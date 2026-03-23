function fullpath_out = movieRemoveHemoComponents(fullpath_in, fullpaths_components, varargin)

    [basepath, filename, ext] = fileparts(fullpath_in);

    options = defaultOptions(basepath);
    if(~isempty(varargin))
        options = getOptions(options, varargin);
    end

    if(options.divide), options.postfix = options.postfix + "D";
    else, options.postfix = options.postfix + "S"; end
    %%    
    
    if (~isfolder(options.outdir)), mkdir(options.outdir); end
    if (~isfolder(options.illustrdir)), mkdir(options.illustrdir); end 
    if (~isfolder(options.diagnosticdir)), mkdir(options.diagnosticdir); end  

    filename_out = filename + options.postfix;
    fullpath_out = fullfile(options.outdir, filename_out + ext);
    
    if (isfile(fullpath_out))
        if(options.skip)
            displog("Output file exists. Skipping: " + fullpath_out);
            return;
        else
            warning("movieRemoveHemoComponents: Output file exists. Deleting: " + fullpath_out);
            delete(fullpath_out);
        end     
    end
    %%
    
    displog("reading movie");
    [M, specs] = rw.h5readMovie(fullpath_in);
    %%
    
    displog("removing components");
    Mout = M;
    M_mean = mean(M, 3);
    if(specs.extra_specs.isKey("mean_substracted")) 
        M_mean = specs.extra_specs("mean_substracted");
    end
    
    if(specs.extra_specs.isKey("expBaseline_A"))
        M_mean = specs.extra_specs("expBaseline_A");
    end
    
    for i_c = 1:length(fullpaths_components)
        fullpath_c = fullpaths_components(i_c);
        [Mc, specs_c] = rw.h5readMovie(fullpath_c);

        dframes = specs_c.timeorigin - specs.timeorigin;
        
        validframesM = false(size(Mout,3),1);
        validframesM( (max(dframes,0)+1):(min(dframes+size(Mc,3), size(Mout,3))) ) = true;
        
        
        validframesC = false(size(Mc,3),1);
        validframesC( (max(-dframes,0)+1):(min(-dframes+size(Mout,3), size(Mc,3))) ) = true;

        % there is no way the modulation is 150% - edge artifact due to mc
%         to_nan = double(any(1.5*M_mean < abs(Mc(:,:,validframesC)), 3));
%         to_nan(logical(to_nan)) = NaN; to_nan(~isnan(to_nan)) = 1;
%         if(any(isnan(to_nan), 'all')) warning('modulation above 50% -> nan'); end
%         Mc = Mc.*to_nan;
        
        if(options.divide)
            Mout(:,:,validframesM) = (M_mean + Mout(:,:,validframesM))./(1 + Mc(:,:,validframesC)./M_mean) - M_mean;%(M_mean + Mout(:,:,validframesM))./(1 + Mc(:,:,validframesC)./M_mean) - M_mean;
        else
            Mout(:,:,validframesM) = Mout(:,:,validframesM) - Mc(:,:,validframesC);
        end
        Mout(:,:, ~validframesM) = NaN;
    end
    %%

    displog("saving");
    keep_frames = squeeze(~all(isnan(Mout), [1,2]));
    start_frame = find(keep_frames, 1, 'first');

    specs_new = specs;
    specs_new.AddToHistory(functionCallStruct(...
        {'fullpath_movie', 'fullpaths_components', 'options'}));
    specs_new.AddFrameDelay(start_frame - 1);

    rw.h5saveMovie(fullpath_out, Mout(:,:,keep_frames), specs_new);
    %%

    displog("saving plots and videos")

    savePlots(M(:,:,keep_frames), Mout(:,:,keep_frames), specs, filename_out, options);


    displog("saving metrics")
    saveMetrics(M(:,:,keep_frames), Mout(:,:,keep_frames), specs, filename_out, options);
end
%%

function options = defaultOptions(basepath)
    
    options.divide = false;
    
    options.outdir = basepath;
    options.illustrdir = fullfile(basepath, 'illustrations');
    options.diagnosticdir = fullfile(basepath, 'diagnostic', 'movieRemoveHemoComponents');
    options.postfix = "_nohemo";  

    options.skip = true;
end
%%

function savePlots(M, Mout, specs, filename_out, options)
    %%
    fig_time = plt.getFigureByName("movieRemoveHemoComponents: Spatially-averaged traces");
    
    m =  squeeze(mean(M,[1,2],'omitnan'));
    m_out =  squeeze(mean(Mout,[1,2],'omitnan'));
    
    plt.tracesComparison([m, m_out], ...
        'labels',["Input", "Nohemo"] + " (mean)",...
        'fps', specs.getFps(), 'fw', 0.2, 'f0', specs.getFrequencyRange(1))  

    fig_space = plt.getFigureByName("movieRemoveHemoComponents: spatial variance");
    imagesc(100*(1-var(Mout, [], 3,'omitnan')./var(M, [], 3,'omitnan')));
    cb = colorbar(); cb.Label.String = "Variance decrease, %"; 
    cb.Label.Rotation = -90; cb.Label.Position = cb.Label.Position + [1,0,0];
   
    %%
    
    saveas(fig_time, fullfile(options.diagnosticdir, filename_out + "_meantraces" + ".png"))
    saveas(fig_time, fullfile(options.diagnosticdir, filename_out + "_meantraces" + ".fig"))
    saveas(fig_space, fullfile(options.diagnosticdir, filename_out + "_variance" + ".png"))
    saveas(fig_space, fullfile(options.diagnosticdir, filename_out + "_variance" + ".fig"))
end
%%

function saveMetrics(M, Mout, specs, filename_out, options)
    %%

    m     = squeeze(mean(M,    [1,2], 'omitnan'));
    m_out = squeeze(mean(Mout, [1,2], 'omitnan'));

    % rc_var: variance ratio from spatially averaged traces
    rc_var = var(m_out) / var(m - m_out);

    % rc_pix: mode of per-pixel var(nohemo)/var(hemo_removed), matching rc_compute histogram approach
    var_in  = var(M,    [], 3, 'omitnan');
    var_out = var(Mout, [], 3, 'omitnan');
    img_data = 100 * (1 - var_out ./ var_in);
    img_data(img_data < 0) = 0;
    [counts, edges] = histcounts(log(100./img_data(:) - 1), round(numel(img_data)*0.003));
    [~, Imod] = max(counts);
    rc_pix = exp((edges(Imod) + edges(Imod+1)) / 2);

    % rc_psd / rc_lf_psd: Welch PSD ratios
    fps = specs.getFps();
    [psd_out, f] = pwelch(m_out, [], [], [], fps);
    [psd_in,  ~] = pwelch(m,     [], [], [], fps);

    rc_psd = sum(psd_out, 'omitnan') / ...
        (sum(psd_in, 'omitnan') - sum(psd_out, 'omitnan'));

    flims = [0, 10];
    lf = f > flims(1) & f < flims(2);
    rc_lf_psd = sum(psd_out(lf), 'omitnan') / ...
        (sum(psd_in(lf), 'omitnan') - sum(psd_out(lf), 'omitnan'));
    %%

    displog("" + ...
        sprintf("pix coef %.3f, full coef %.3f (%.3f from psd), lf coef %.3f (from psd)\n", ...
        rc_pix, rc_var, rc_psd, rc_lf_psd));

    json_string = jsonencode(struct(...
        'total_in',         var(m), ...
        'total_nohemo',     var(m_out), ...
        'total_in_psd',     sum(psd_in), ...
        'total_nohemo_psd', sum(psd_out), ...
        'rc_pix', rc_pix, 'rq_var', rc_var, 'rq_psd', rc_psd, 'rq_lf_psd', rc_lf_psd));

    fid = fopen(fullfile(options.diagnosticdir, filename_out + "_metrics.json"), 'w');
    fprintf(fid, json_string);
    fclose(fid);
end
%%