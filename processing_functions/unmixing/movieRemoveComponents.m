function fullpath_out = movieRemoveComponents(fullpath_in, fullpaths_components, varargin)
% MOVIEREMOVECOMPONENTS Remove one or more unmixed component movies from an input movie.
%   fullpath_out = MOVIEREMOVECOMPONENTS(fullpath_in, fullpaths_components, ...)
%   reads the movie at fullpath_in and, for each component movie listed in
%   fullpaths_components (e.g. hemodynamic or other unmixed signal
%   components), subtracts it (or divides it out, see the 'divide' option)
%   frame-by-frame after aligning the two movies by their timeorigin
%   timestamps. Frames without full overlap across all components are
%   trimmed from the start/end of the output. Saves the corrected movie,
%   diagnostic comparison plots, and summary metrics to disk.
%
%   Inputs:
%       fullpath_in          - path to the input movie (.h5)
%       fullpaths_components - array of paths to component movies to remove
%       varargin              - name-value options, see defaultOptions()
%
%   Output:
%       fullpath_out - path to the saved, component-removed movie

    [basepath, filename, ext] = fileparts(fullpath_in);

    options = defaultOptions(basepath);
    if(~isempty(varargin))
        options = getOptions(options, varargin);
    end

    if(options.divide), options.postfix_new = options.postfix_new + "D"; end
    %%    
    
    if (~isfolder(options.outdir)), mkdir(options.outdir); end
    if (~isfolder(options.illustrdir)), mkdir(options.illustrdir); end 
    if (~isfolder(options.diagnosticdir)), mkdir(options.diagnosticdir); end  

    filename_out = filename + options.postfix_new;
    fullpath_out = fullfile(options.outdir, filename_out + ext);
    
    if (isfile(fullpath_out))
        if(options.skip)
            displog("Output file exists. Skipping: " + fullpath_out);
            return;
        else
            warning("movieRemoveComponents: Output file exists. Deleting: " + fullpath_out);
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

    specs_new = copy(specs);
    specs_new.AddToHistory(functionCallStruct(...
        {'fullpath_in', 'fullpaths_components', 'options'}));
    specs_new.AddFrameDelay(start_frame - 1);
    specs_new.AddFrequencyRange(...
        max(specs.getFrequencyRange(1), specs_c.getFrequencyRange(1)), ...
        min(specs.getFrequencyRange(2), specs_c.getFrequencyRange(2)));

    rw.h5saveMovie(fullpath_out, Mout(:,:,keep_frames), specs_new);
    %%

    displog("saving plots")

    savePlots(M(:,:,keep_frames), Mout(:,:,keep_frames), specs_new, filename_out, options);


    displog("saving metrics")
    saveMetrics(M(:,:,keep_frames), Mout(:,:,keep_frames), specs_new, filename_out, options);
end
%%

function options = defaultOptions(basepath)
    
    options.divide = false; % if true, remove components by division (ratiometric/demodulation) instead of subtraction; appends "D" to the output postfix

    options.outdir = basepath;
    options.illustrdir = fullfile(basepath, 'illustrations');
    options.diagnosticdir = fullfile(basepath, 'diagnostic', 'removeComponents');
    options.postfix_new = "_nocomp";

    options.skip = true; % if true, skip processing (return early) when the output file already exists; if false, delete and regenerate it
end
%%

function savePlots(M, Mout, specs, filename_out, options)
    %%
    fig_trace = plt.getFigureByName("movieRemoveComponents: Spatially-averaged traces");
    
    m =  squeeze(mean(M,[1,2],'omitnan'));
    m_out =  squeeze(mean(Mout,[1,2],'omitnan'));
    
    plt.tracesComparison([m, m_out, m-m_out], ...
        'labels',["Input", "Nocomp", "Removed"] + " (mean)",...
        'fps', specs.getFps(), 'fw', 0.2, 'f0', specs.getFrequencyRange(1),...
        'spacebysd', [0,0,5])  
    %%
    fig_trace1 = plt.getFigureByName("movieRemoveComponents: Single-pixel traces");

    pix = round(size(M,[1,2])/2);

    m =  squeeze(M(pix(1),pix(2),:));
    m_out =  squeeze(Mout(pix(1),pix(2),:));

    plt.tracesComparison([m, m_out, m-m_out], ...
        'labels',["Input", "Nocomp", "Removed"] + " (pixel)",...
        'fps', specs.getFps(), 'fw', 0.2, 'f0', specs.getFrequencyRange(1),...
        'spacebysd', [0,0,5])  
    %%

    fig_space = plt.getFigureByName("movieRemoveComponents: spatial variance");
    fig_space.Position(4) = 300;
    fig_space.Position(3) = 900;
    
    var_in  = var(M, [], 3,'omitnan');
    var_out = var(Mout, [], 3,'omitnan');

    ax = subplot(1,2,1);
    imagesc(sqrt(var_in-var_out));
    axis equal; axis off;
    cb = colorbar(); cb.Label.String = "Variance decrease (counts)"; 
    cb.Label.Rotation = -90; cb.Label.Position = cb.Label.Position + [1,0,0];
     
    subplot(1,2,2)
    imagesc(100*(1-var_out./var_in));
    axis equal; axis off;
    cb = colorbar(); cb.Label.String = "Variance decrease (%)"; 
    cb.Label.Rotation = -90; cb.Label.Position = cb.Label.Position + [1,0,0];
   
    %%
    
    saveas(fig_trace, fullfile(options.diagnosticdir, filename_out + "_meantraces" + ".png"))
    saveas(fig_trace, fullfile(options.diagnosticdir, filename_out + "_meantraces" + ".fig"))
    saveas(fig_trace1, fullfile(options.diagnosticdir, filename_out + "_pixtraces" + ".png"))
    saveas(fig_trace1, fullfile(options.diagnosticdir, filename_out + "_pixtraces" + ".fig"))
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

    % rc_pix: mode of per-pixel var(nocomp)/var(hemo_removed), matching rc_compute histogram approach
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