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
    meanmovie = double(squeeze(mean(Min, [1,2], 'omitnan')));

    % a - baseline fluorescence (F0); b1 - bleaching timescale; c1 - fraction of bleaching; c2 - first order approximation to slower dynamics
    baseline = @(a, b1, c1, c2, x) a.*(1 + c1.*exp(-x./b1) - c2.*x);  
    
    fo = fitoptions('Method','NonlinearLeastSquares',...
                    'StartPoint', [min(meanmovie), 20*specs.getFps(), 0.1, 0],...
                    'lower',[0 options.tmin*specs.getFps() 0 0],'upper',[Inf Inf 1 Inf]);

    f0=fit(ts, meanmovie, baseline, fo);
    %%

    fo1 = copy(fo);
    fo1.Upper(4) = 0;
    f01=fit(ts, meanmovie, baseline, fo1);
    
    useC2 = true;
    % if improvement is less that 10%, don't use free term c2
    if(norm(f01(ts)-meanmovie)/norm(f0(ts)-meanmovie)-1 < 1e-1)
        useC2 = false;
        f0 = f01;     
    end
        
    ga = f0.a/min(meanmovie);
    %%

    fig_mean = plt.getFigureByName("movieExpBaselineCorrection - mean trace");
    plot(f0, ts, meanmovie, '-'); drawnow;
    %%
    
    disp("movieExpBaselineCorrection: fitting for every pix");
    
    nx = size(Min, 1); ny = size(Min, 2);
    
    A = nan([nx*ny, 1]);
    B1 = nan([nx*ny, 1]);
    C1 = nan([nx*ny, 1]);
    C2 = nan([nx*ny, 1]);
    
    Min = reshape(Min, [nx*ny, size(Min, 3)]);
    %%
    
    X1 = f0.a*ones(size(Min,2),1);
    X2 = f0.a*f0.c1*exp(-ts/f0.b1);
    X3 = -f0.a*f0.c2*ts;
    nan_pos = any(isnan(Min), 2);
    %%
    
    if(useC2)
        ft = [X1, X2, X3]\Min(~nan_pos, :)';
    else 
        ft = [X1, X2]\Min(~nan_pos, :)';
    end
        
    A(~nan_pos) = ft(1,:)*f0.a; A(A<0) = 0;
    B1(~nan_pos) = f0.b1; 
    C1(~nan_pos) = ft(2,:)*f0.c1./(ft(1,:)+1e-4); C1(C1 < 0) = 0; C1(C1>2) = 2;
    if(useC2) C2(~nan_pos) = ft(3,:)*f0.c2; else C2(~nan_pos) = f0.c2; end 
    C2(C2<0) = 0;
    %%
    
%         fo = fitoptions('Method','NonlinearLeastSquares',...
%                     'StartPoint', [min(meanmovie), double(max(ts))/4, 0.1, 0],...
%                     'lower',[0 options.tmin*specs.getFps() 0 0],'upper',[Inf Inf 1 Inf]);
    %%
    
    A = reshape(A, [nx,ny]);
    B1 = reshape(B1, [nx,ny]);
    C1 = reshape(C1, [nx,ny]);
    C2 = reshape(C2, [nx,ny]);
    
    Min = reshape(Min, [nx,ny,size(Min,2)]);
    %%
    
    fig_coef = plt.getFigureByName("movieExpBaselineCorrection - coefficients");
    subplot(2,4,1); imshow(A, []); colorbar; title('A');
    subplot(2,4,2); imshow(C1, []); colorbar; title('C_1 (rel)');
    subplot(2,4,3); imshow(B1/specs.getFps(), []); colorbar; title('B_1 (s)');
    subplot(2,4,4); imshow(C2*specs.getFps(), []); colorbar; title('C_2 (s^{-1})');
    
    subplot(2,4,5); histogram(A);
    subplot(2,4,6); histogram(C1);
    subplot(2,4,7); histogram(B1/specs.getFps());
    subplot(2,4,8); histogram(C2*specs.getFps());
    
    sgtitle("m=a(1 + c_1exp(-t/b_1) - c_2t)")
    %%
    
    % not an ideal soution for the cases when the exponent fitted has huge
    % decay time and overcorrects
    Mout = Min ./ (baseline(1, B1, C1, C2, permute(ts,[3,2,1])) - ...
                   baseline(1, B1, C1, C2, ts(end))+1);

    fig_comp = plt.getFigureByName("movieExpBaselineCorrection - traces");
    plt.tracesComparison([squeeze(mean(Min, [1,2], 'omitnan')), squeeze(mean(Mout, [1,2], 'omitnan'))], ...
        'fps', specs.getFps(), 'fw', 0.5, 'labels', ["raw", "baseline-corrected"], 'nomean', false)
    %%
    disp("movieExpBaselineCorrection: saving")
    
    specs_out = copy(specs);
    specs_out.AddToHistory(functionCallStruct({'fullpath_movie', 'options'}));
    specs_out.extra_specs("expBaseline_A") = A;
    specs_out.extra_specs("expBaseline_C1") = C1;
    specs_out.extra_specs("expBaseline_B1") = B1;
    specs_out.extra_specs("expBaseline_C2") = C2;
    
    rw.h5saveMovie(fullpath_out, Mout, specs_out);
    
    saveas(fig_mean, fullfile(options.diagnosticdir, filename_out + "_mean.png"))
    saveas(fig_mean, fullfile(options.diagnosticdir, filename_out + "_mean.fig"))
    saveas(fig_coef, fullfile(options.diagnosticdir, filename_out + "_coefs.png"))
    saveas(fig_coef, fullfile(options.diagnosticdir, filename_out + "_coefs.fig"))
    saveas(fig_comp, fullfile(options.diagnosticdir, filename_out + "_mean.png"))
    saveas(fig_comp, fullfile(options.diagnosticdir, filename_out + "_mean.fig"))
end
%%

function options = defaultOptions(basepath)
    
    options.diagnosticdir = basepath + "\diagnostic\expBaselineCorrection\";
    options.outdir = basepath;
    options.skip = true;
    options.tmin = 2; %s
end
%%
