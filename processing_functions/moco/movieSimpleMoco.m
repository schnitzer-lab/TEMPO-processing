
% 2x movie size ram
function [fullpath_out,fullpath_out_shifts] = movieSimpleMoco(fullpath_movie, varargin)
    
     [basepath, filename, ext]  = fileparts(fullpath_movie);

    options = defaultOptions(basepath);
    if(~isempty(varargin))
        options = getOptions(options, varargin);
    end

    postfix_new = "_mc";
    %%
    
    if (~isfolder(options.processingdir)), mkdir(options.processingdir); end
    if (~isfolder(options.diagnosticdir)), mkdir(options.diagnosticdir); end

    fullpath_out = fullfile(options.outdir, filename + postfix_new + ext);
    fullpath_out_shifts = fullfile(options.processingdir, filename + postfix_new + '.txt');
    
    if (isfile(fullpath_out))
        if(options.skip)
            displog("Output file exists. Skipping: " + fullpath_out)
            return;
        else
            warning("movieSimpleMoco: Output file exists. Deleting: " + fullpath_out);
            delete(fullpath_out);
        end     
    end
    %%

    displog("reading movie")
    specs = rw.h5readMovieSpecs(fullpath_movie);
    [~,~,nt] = rw.h5getDatasetSize(fullpath_movie, '/mov');
%     [M, specs] = rw.h5readMovie(fullpath_movie);
    %%
    
    if(options.bandpass)
        lower_threshold = 2*round(options.bandpass(1)/specs.getPixSize()/2)+1;
        upper_threshold = 2*round(options.bandpass(2)/specs.getPixSize()/2)+1;
        spatial_filter = @(data) ...
            smoothdata(smoothdata(data, 1, 'gaussian', upper_threshold), 2, 'gaussian', upper_threshold )-...
            smoothdata(smoothdata(data, 1, 'gaussian', lower_threshold), 2, 'gaussian', lower_threshold);
    else
        spatial_filter = @(data) data; 
    end
        
    fig_filtered = plt.getFigureByName("movieSimpleMoco: Frame filtering example"); clf;
    subplot(1,2,1)
    imshow(spatial_filter(rw.h5readMovie(fullpath_movie, 'frame_start', round(nt/2), 'frames_num', 1)), []);
    title("frame " + num2str(round(nt/2)) + " filtered");
    drawnow;
    %%
    
    Mf = rw.h5readMovie(fullpath_movie); 
    shifts = zeros([size(Mf,3),2]); 
    nan_poins = false(size(Mf));
    for it = 1:options.niteration
        
        displog("finding shifts - iteration " + ...
            sprintf("%d/%d", it, options.niteration) );
        [Mf, shifts2, template] = dftMoco2(Mf,...
            'spatial_filter', spatial_filter, ...
            'upsample', options.upsample_factor*specs.binning);
        shifts = shifts + shifts2;
        
        nan_poins = nan_poins | isnan(Mf) ; 

        % setting nan to 0 produces sharp edges, that can owerwhelm the template
        Mf = imputeNaNT(Mf); 
        if(any(isnan(Mf(:))))
            warning("movieSimpleMoco: constant shift")
            Mf = imputeNaNS(Mf);
        end
    end
    
%     Mf(nan_poins) = NaN;
    nan_mask = ones(size(Mf, [1,2]), class(Mf));
    nan_mask(any(nan_poins,3)) = NaN;

    Mf = Mf.*nan_mask;
    template = template.*nan_mask;
    %%
      
    plt.getFigureByName("movieSimpleMoco: Frame filtering example");
    subplot(1,2,2)
    imshow(template, []); title("final template");
    %%
    
    fig_shifts = plt.getFigureByName("Shifts traces"); clf;
    plt.tracesComparison([shifts(:,1), shifts(:,2)], ...
        'nomean', false, 'labels', ["x_shift", "y_shift"], 'fps', specs.getFps(), 'fw', 0.1);        
    %%
       
    w = round(2*specs.getFps()); % 2 second timewindow
    dw = round(w/2); % 50% overlap
    nw = 1*w/specs.getFps()/2; % 1 Hz spectral resolution
    
    [st_x,fs,ts] = proc.SpectrogramMultitaper(shifts(:,1), w, 'overlap', dw, 'nw', nw, 'fps', specs.getFps());
    [st_y,~,~]   = proc.SpectrogramMultitaper(shifts(:,2), w, 'overlap', dw, 'nw', nw, 'fps', specs.getFps());
    
    ts = ts + (specs.timeorigin-1)/specs.getFps();
        
    options_spectrogram = struct('q', [0.001, 0.999], 'flims_plot', [0, specs.getFps()/2], ...
        'trace_ts', ((0:(size(shifts,1)-1)) + (specs.timeorigin-1))'/specs.getFps(), ...
        'spectra_fs', fs);
    
    fig_shifts_x = plt.getFigureByName("movieSimpleMoco: Shifts traces x"); clf;
    options_spectrogram.title = [basepath, filename, "x-shifts"];
    options_spectrogram.trace = shifts(:,1);
    options_spectrogram.spectra = mean(st_x, 2, 'omitnan');
    plt.signalSpectrogram(st_x, ts, fs, options_spectrogram);
        
    fig_shifts_y = plt.getFigureByName("movieSimpleMoco: Shifts traces y"); clf;  
    options_spectrogram.title = [basepath, filename, "y-shifts"];
    options_spectrogram.trace = shifts(:,2);
    options_spectrogram.spectra = mean(st_y, 2, 'omitnan');
    plt.signalSpectrogram(st_y, ts, fs, options_spectrogram);
    %%
    
    M = rw.h5readMovie(fullpath_movie);
    M(isnan(Mf)) = NaN;    
    %%
    
    fig_mean = plt.getFigureByName("movieSimpleMoco: mean traces");
    pix_xy = round(size(M,[1,2])/2);

    m0 = (squeeze( M(pix_xy(1),pix_xy(2),:)));
    mf = (squeeze(Mf(pix_xy(1),pix_xy(2),:)));
    sha = sqrt(sum(shifts.^2,2));
    
    plt.tracesComparison([m0, mf,sha*std(m0)/std(sha)/5], 'fps', specs.getFps(), 'fw', 0.5,...
        'labels', ["single pix trace - initial", "single pix trace - mc", "displacement (scaled)"])
    sgtitle("Pixel " + strjoin(string(pix_xy), ','))
    %%

    fig_var = plt.getFigureByName("movieSimpleMoco: variance change");
    s0 = var( M,[], 3);
    s1 = var(Mf,[], 3);

    subplot(1,2,1);
    imshow(s1-s0,[]);
    colormap(plt.redblue);
    caxis(max(abs(s1-s0), [], 'all')*[-1,1]);

    subplot(1,2,2);
    histogram(s1-s0, 300, 'BinLimits', quantile(s1(:)-s0(:), [0.05, 0.95]));
    xline(median(s1-s0, 'all', 'omitnan'), 'LineWidth',2,'LineStyle', '--');
    xlim(quantile(s1(:)-s0(:), [0.2, 0.8]));
    legend(["Variance change", "median"], 'Location', 'northwest');
    set(gca, 'XGrid', 'on', 'YGrid', 'off');
    
    sgtitle('per-pix variance change due to mc');
    %%
    displog("saving");
     
    specs_out = copy(specs);
    specs_out.AddToHistory(functionCallStruct({'fullpath_movie', 'options'}));
    rw.h5saveMovie(fullpath_out, Mf, specs_out);
    %%
    
    writematrix(shifts, fullpath_out_shifts);
    saveas(fig_filtered, fullfile(options.diagnosticdir, filename + "_bandpass.png"))
    saveas(fig_filtered, fullfile(options.diagnosticdir, filename + "_bandpass.fig"))
    saveas(fig_shifts, fullfile(options.diagnosticdir, filename + "_shifts.png"))
    saveas(fig_shifts, fullfile(options.diagnosticdir, filename + "_shifts.fig"))
    saveas(fig_shifts_x, fullfile(options.diagnosticdir, filename + "_shifts_x.png"))
    saveas(fig_shifts_x, fullfile(options.diagnosticdir, filename + "_shifts_x.fig"))
    saveas(fig_shifts_y, fullfile(options.diagnosticdir, filename + "_shifts_y.png"))
    saveas(fig_shifts_y, fullfile(options.diagnosticdir, filename + "_shifts_y.fig"))
    saveas(fig_mean, fullfile(options.diagnosticdir, filename + "_mean.png"))
    saveas(fig_mean, fullfile(options.diagnosticdir, filename + "_mean.fig"))
    saveas(fig_var, fullfile(options.diagnosticdir, filename + "_var.png"))
    saveas(fig_var, fullfile(options.diagnosticdir, filename + "_var.fig"))
end
%%

function options = defaultOptions(basepath)
    
    options.outdir = basepath;
    options.illustrdir = fullfile(basepath, 'illustrations');
    options.processingdir = fullfile(basepath, 'processing' ,'movieFindMocoShifts');
    options.diagnosticdir = fullfile(basepath, 'diagnostic', 'movieFindMocoShifts');
    options.bandpass = [0.0500 0.5000]; %mm
    options.max_shift = [0.5, 0.5]; %mm
    options.upsample_factor = 8; 
    options.niteration = 2;
    
    options.skip = true;
end
%%
