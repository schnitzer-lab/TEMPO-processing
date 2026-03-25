function fullpath_out = movieExpBaselineCorrection(fullpath_movie, varargin)
    
    [basepath, filename, ext] = fileparts(fullpath_movie);

    options = defaultOptions(basepath);
    if(~isempty(varargin))
        options = getOptions(options, varargin);
    end

    postfix_new = "_expBlC";
    %%
    
    if (~isfolder(options.outdir)), mkdir(options.outdir); end
    if (~isfolder(options.diagnosticdir)), mkdir(options.diagnosticdir); end

    filename_out = filename + postfix_new;
    fullpath_out = fullfile(options.outdir, filename_out + ext);
    
    if (isfile(fullpath_out))
        if(options.skip)
            displog("Output file exists. Skipping: " + fullpath_out)
            return;
        else
            warning("movieExpBaselineCorrection: Output file exists. Deleting: " + fullpath_out);
            delete(fullpath_out);
        end     
    end
    %%
    
    displog("reading movie")
    
    [Min, specs] = rw.h5readMovie(fullpath_movie);
    %%
    
    displog("fitting for the mean trace")
    ts = (1:size(Min, 3))';

    nan_mask = ones(size(Min,[1,2]));
    if(~isempty(specs.getMask()))
        nan_mask = nan_mask.*specs.getMaskNaN();
    end
    m = squeeze(mean(Min.*nan_mask, [1,2], 'omitnan')); 
    %%

    baseline = @(a, b1, c1, b2, c2, x) (a + c1.*exp(-x./b1) + c2.*exp(-x./b2));  
    
    fo = fitoptions('Method','NonlinearLeastSquares',...
                    'StartPoint', [mean(m), 20*specs.getFps(), 0, 200*specs.getFps(), 0],...
                    'lower',[0 options.tmin*specs.getFps() 0 options.tmin*specs.getFps() 0], ...
                    'upper',[Inf length(m)/2 Inf Inf Inf]);

    f0=fit(ts, double(m), baseline, fo);
    %%

    fo1 = copy(fo);
    fo1.Upper(5) = fo1.Lower(5); fo1.Upper(4) = fo1.Lower(4);
    f01=fit(ts, double(m), baseline, fo1);
    
    useC2 = true;
    % if improvement is less, don't use free term c2
    if(norm(f01(ts)-m)/norm(f0(ts)-m)-1 < options.twoexpimpr )
        useC2 = false; f0 = f01;     
    end
    %%

    fig_meanfit = plt.getFigureByName("movieExpBaselineCorrection - mean trace");
    plot(f0, ts, m, '-'); xlabel("frame #"); 
    text(0.15*mean(ts), max(get(gca, 'YLim')) - 0.2*diff(get(gca, 'YLim')), evalc('f0'))
    drawnow;
    %%
    
    displog("fitting for every pix");
    
    nx = size(Min, 1); ny = size(Min, 2);
    
    A = nan([nx*ny, 1]);
    B1 = nan([nx*ny, 1]); C1 = nan([nx*ny, 1]);
    B2 = nan([nx*ny, 1]); C2 = nan([nx*ny, 1]);
    %%
    
    X1 = f0.a*ones(length(ts),1);
    X2 = f0.c1*exp(-ts/f0.b1);
    X3 = f0.c2*exp(-ts/f0.b2);
    %%

    Min = reshape(Min, [nx*ny, size(Min, 3)]);
    
    if(useC2), X = [X1, X2, X3]; else, X = [X1,X2]; end
    ft = NaN(size(X,2), size(Min,1));
    parfor ipix = 1:size(Min,1)
        if(any(isnan(Min(ipix,:)))), continue; end
        ft(:, ipix) = lsqnonneg(X,  double(Min(ipix,:))');
    end
    %%

    A(:)= ft(1,:)*f0.a;
    B1(:) = f0.b1; C1(:) = ft(2,:)*f0.c1;
    B2(:) = f0.b2; C2(:) = f0.c2;
    if(useC2), C2(:) = ft(3,:)*f0.c2; end 
    %%
    
    A = reshape(A, [nx,ny]);
    B1 = reshape(B1, [nx,ny]); C1 = reshape(C1, [nx,ny]);
    B2 = reshape(B2, [nx,ny]); C2 = reshape(C2, [nx,ny]);
    
    Min = reshape(Min, [nx,ny,size(Min,2)]);
    %%
    
    fig_coef = plt.getFigureByName("movieExpBaselineCorrection - coefficients");
    subplot(2,3,1); imshow(A, []); colorbar; title('A');
    subplot(2,3,2); imshow(plt.saturate(C1, [0,0.99]), []); colorbar; title('C_1');
    subplot(2,3,3); imshow(plt.saturate(C2, [0,0.99]), []); colorbar; title('C_2');
    
    subplot(2,3,4); histogram(plt.saturate(A,[0,0.99]));
    subplot(2,3,5); histogram(plt.saturate(C1,[0,0.99])); 
    subplot(2,3,6); histogram(plt.saturate(C2,[0,0.99])); 
    
    sgtitle("M = (A + C_1exp(-t/b_1) + C_2exp(-t/b_2)), " + ...
            sprintf("b_1=%.1fs, b_2=%.1fs", f0.b1/specs.getFps(), f0.b2/specs.getFps()) )
    %%
    
    Mbl = (baseline(A, B1, C1, B2, C2, permute(ts,[3,2,1])));
    
    % correction to the final value in recording
    if(options.divide)
        Mout = Min./(Mbl./Mbl(:,:,end));
    else
        Mout = Min - (Mbl - Mbl(:,:,end));
    end
    %%

    mout = squeeze(mean(Mout.*nan_mask, [1,2], 'omitnan'));
    bl = squeeze(mean(Mbl.*nan_mask, [1,2], 'omitnan'));
    
    r2 = norm(m-bl) / norm(m);
    a =  median(m-bl) / std(m-bl);

    fig_meanout = plt.getFigureByName("movieExpBaselineCorrection - traces");
    plt.tracesComparison([m, mout, bl], ...
        'fps', specs.getFps(), 'fw', 0.1, 'labels', ["raw", "baseline-corrected", "baseline"], ...
        'nomean', false, 'spectrum', false)
    title(sprintf("baseline correction (rs=%.2f, a=%.1f)", r2, a))
    %%
    
    if(r2 > options.r2_thresh), error('bad fit - fit difference'); end
    if(abs(a) > options.a_thresh), error('bad fit - fit asymmetry'); end
    %%
    
    displog("saving")
    
    specs_out = copy(specs);
    specs_out.AddToHistory(functionCallStruct({'fullpath_movie', 'options'}));
    specs_out.extra_specs("expBaseline_A") = A;
    specs_out.extra_specs("expBaseline_end") = Mbl(:,:,end);
    
    rw.h5saveMovie(fullpath_out, Mout, specs_out);
    
    saveas(fig_meanfit, fullfile(options.diagnosticdir, filename_out + "_mean_fit.png"))
    saveas(fig_meanfit, fullfile(options.diagnosticdir, filename_out + "_mean_fit.fig"))
    saveas(fig_coef, fullfile(options.diagnosticdir, filename_out + "_coefs.png"))
    saveas(fig_coef, fullfile(options.diagnosticdir, filename_out + "_coefs.fig"))
    saveas(fig_meanout, fullfile(options.diagnosticdir, filename_out + "_mean.png"))
    saveas(fig_meanout, fullfile(options.diagnosticdir, filename_out + "_mean.fig"))
end
%%

function options = defaultOptions(basepath)
    
    options.diagnosticdir = fullfile(basepath, 'diagnostic', 'expBaselineCorrection');
    options.outdir = basepath;

    options.tmin = 2; %s
    options.twoexpimpr = 0; % use 2-exp model if there is relative improvement more than twoexpimpr
    options.r2_thresh = 0.1;
    options.a_thresh = 1; 

    options.divide = false;

    options.skip = true;
end
%%
