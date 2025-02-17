function fullpath_out = movieExpBaselineCorrection(fullpath_movie, varargin)
    
    [basepath, basefilename, ext, postfix] = filenameSplit(fullpath_movie, '_');

    options = defaultOptions(basepath);
    if(~isempty(varargin))
        options = getOptions(options, varargin);
    end

    postfix_new = "_expBlC";
    %%
    
    if (~isfolder(options.outdir)) mkdir(options.outdir); end
    if (~isfolder(options.diagnosticdir)) mkdir(options.diagnosticdir); end

    filename_out = basefilename + postfix + postfix_new;
    fullpath_out = fullfile(options.outdir, filename_out + ext);
    
    if (isfile(fullpath_out))
        if(options.skip)
            disp("movieExpBaselineCorrection: Output file exists. Skipping: " + fullpath_out)
            return;
        else
            warning("movieExpBaselineCorrection: Output file exists. Deleting: " + fullpath_out);
            delete(fullpath_out);
        end     
    end
    %%
    
    disp("movieExpBaselineCorrection: reading movie")
    
    [Min, specs] = rw.h5readMovie(fullpath_movie);

    %%
    
    disp("movieExpBaselineCorrection: fitting for the mean trace")
    ts = (1:size(Min, 3))';

    nan_mask = ones(size(Min, [1,2]));
    if(~isempty(specs.getMask())) nan_mask(specs.getMask() == 0) = NaN; end

    meanmovie = double(squeeze(mean(Min.*nan_mask, [1,2], 'omitnan')));

    %%
    % a - baseline fluorescence (F0); b1 - bleaching timescale; c1 - fraction of bleaching; c2 - first order approximation to slower dynamics
%     baseline = @(a, b1, c1, c2, x) a.*(1 + c1.*exp(-x./b1) - c2.*x);  
    baseline = @(a, b1, c1, b2, c2, x) a.*(1 + c1.*exp(-x./b1) + c2.*exp(-x./b2));  
    
    fo = fitoptions('Method','NonlinearLeastSquares',...
                    'StartPoint', [min(meanmovie), 20*specs.getFps(), 0.1, 200*specs.getFps(), 0],...
                    'lower',[0 options.tmin*specs.getFps() 0 options.tmin*specs.getFps() 0],'upper',[Inf Inf 1 Inf 1]);

    f0=fit(ts, meanmovie, baseline, fo);
    %%

    fo1 = copy(fo);
    fo1.Upper(5) = fo1.Lower(5);
    fo1.Upper(4) = fo1.Lower(4);
    f01=fit(ts, meanmovie, baseline, fo1);
    
    useC2 = true;
    % if improvement is less that 5%, don't use free term c2
    if(norm(f01(ts)-meanmovie)/norm(f0(ts)-meanmovie)-1 < options.twoexpimpr )
        useC2 = false;
        f0 = f01;     
    end
        
    ga = f0.a/min(meanmovie);
    %%

    fig_meanfit = plt.getFigureByName("movieExpBaselineCorrection - mean trace");
    plot(f0, ts, meanmovie, '-'); 
    xlabel("frame"); 
    text(0.15*mean(ts), max(get(gca, 'YLim')) - 0.2*diff(get(gca, 'YLim')), evalc('f0'))
    drawnow;
    %%
    
    disp("movieExpBaselineCorrection: fitting for every pix");
    
    nx = size(Min, 1); ny = size(Min, 2);
    
    A = nan([nx*ny, 1]);
    B1 = nan([nx*ny, 1]);
    C1 = nan([nx*ny, 1]);
    B2 = nan([nx*ny, 1]);
    C2 = nan([nx*ny, 1]);
    
    Min = reshape(Min, [nx*ny, size(Min, 3)]);
    %%
    
    X1 = f0.a*ones(size(Min,2),1);
    X2 = f0.a*f0.c1*exp(-ts/f0.b1);
    X3 = f0.a*f0.c2*exp(-ts/f0.b2);
    nan_pos = any(isnan(Min), 2);
    %%
    
    if(useC2)
        ft = [X1, X2, X3]\Min(~nan_pos, :)';
    else 
        ft = [X1, X2]\Min(~nan_pos, :)';
    end

    %%
        
    A(~nan_pos) = ft(1,:)*f0.a; A(A<0) = 0;
    B1(~nan_pos) = f0.b1; 
    C1(~nan_pos) = ft(2,:)*f0.c1./(ft(1,:)+eps); C1(C1 < 0) = 0; %C1(C1>1) = 1;
    
    B2(~nan_pos) = f0.b2; 
    C2(~nan_pos) = f0.c2;
    if(useC2) 
        C2(~nan_pos) = ft(3,:)*f0.c2./(ft(1,:)+eps); C2(C2 < 0) = 0; %C2(C2>1) = 1;
    end 
    C2(C2<0) = 0;
    %%
    
    A = reshape(A, [nx,ny]);
    B1 = reshape(B1, [nx,ny]);
    C1 = reshape(C1, [nx,ny]);
    B2 = reshape(B2, [nx,ny]);
    C2 = reshape(C2, [nx,ny]);
    
    Min = reshape(Min, [nx,ny,size(Min,2)]);
    %%
    
    fig_coef = plt.getFigureByName("movieExpBaselineCorrection - coefficients");
    subplot(2,3,1); imshow(A, []); colorbar; title('A');
    subplot(2,3,2); imshow(plt.saturate(C1, [0,0.9]), []); colorbar; title('C_1 (rel)');
    subplot(2,3,3); imshow(plt.saturate(C2, [0,0.9]), []); colorbar; title('C_2 (rel)');
    
    subplot(2,3,4); histogram(plt.saturate(A,[0,0.99]));
    subplot(2,3,5); histogram(plt.saturate(C1,[0,0.99])); 
    subplot(2,3,6); histogram(plt.saturate(C2,[0,0.99])); 
    
    sgtitle(["M = A(1 + C_1exp(-t/b_1) + C_2exp(-t/b_2)), " + ...
             sprintf("b_1=%.1fs, b_2=%.1fs", f0.b1/specs.getFps(), f0.b2/specs.getFps())])
    %%
    
    Mbl = (baseline(A, B1, C1, B2, C2, permute(ts,[3,2,1])));
    
    % correction to the final value in recording not an ideal soution, 
    % but needed for the cases when the exponent fitted has huge
    % decay time and overcorrects
    if(options.divide)
        Mout = Min./(Mbl./Mbl(:,:,end));
    else
        Mout = Min - (Mbl - Mbl(:,:,end));
    end

    %%

    fig_meanout = plt.getFigureByName("movieExpBaselineCorrection - traces");
    plt.tracesComparison([...
        squeeze(mean(Min, [1,2], 'omitnan')), ...
        squeeze(mean(Mout, [1,2], 'omitnan')), ...
        squeeze(mean(Mbl, [1,2], 'omitnan'))], ...
        'fps', specs.getFps(), 'fw', 0.5, 'labels', ["raw", "baseline-corrected", "baseline"], ...
        'nomean', false)
    %%
    disp("movieExpBaselineCorrection: saving")
    
    specs_out = copy(specs);
    specs_out.AddToHistory(functionCallStruct({'fullpath_movie', 'options'}));
    specs_out.extra_specs("expBaseline_A") = A;
    specs_out.extra_specs("expBaseline_end") = Mbl(:,:,end);
%     specs_out.extra_specs("expBaseline_C1") = C1;
%     specs_out.extra_specs("expBaseline_B1") = B1;
%     specs_out.extra_specs("expBaseline_C2") = C2;
    
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
    options.twoexpimpr = 5e-2; % use 2-exp model if there is at least 5% improvement
    options.divide = false;

      options.skip = true;
end
%%
