
% 2x movie size ram
function [fullpath_out,fullpath_out_shifts] = movieSimpleMoco(fullpath_movie, varargin)
    
     [basepath, filename, ext, ~, ~, ~]  = filenameParts(fullpath_movie);

    options = defaultOptions(basepath);
    if(~isempty(varargin))
        options = getOptions(options, varargin);
    end

    postfix_new = "_mc";
    %%
    
    if (~isfolder(options.processingdir)) mkdir(options.processingdir); end
    if (~isfolder(options.diagnosticdir)) mkdir(options.diagnosticdir); end

    fullpath_out = fullfile(options.outdir, filename + postfix_new + ext);
    fullpath_out_shifts = fullfile(options.processingdir, filename + postfix_new + '.txt');
    
    if (isfile(fullpath_out))
        if(options.skip)
            disp("movieSimpleMoco: Output file exists. Skipping: " + fullpath_out)
            return;
        else
            warning("movieSimpleMoco: Output file exists. Deleting: " + fullpath_out);
            delete(fullpath_out);
        end     
    end
    %%

    disp("movieSimpleMoco: reading movie")
    specs = rw.h5readMovieSpecs(fullpath_movie);
    sz = rw.h5getDatasetSize(fullpath_movie, '/mov');
%     [M, specs] = rw.h5readMovie(fullpath_movie);
    %%
    
    if(options.bandpass)
        lower_threshold = options.bandpass(1)/specs.getPixSize();
        upper_threshold = options.bandpass(2)/specs.getPixSize();
        spatial_filter = @(data) ...
            smoothdata(smoothdata(data, 1, 'gaussian', upper_threshold), 2, 'gaussian', upper_threshold )-...
            smoothdata(smoothdata(data, 1, 'gaussian', lower_threshold), 2, 'gaussian', lower_threshold);
    else
        spatial_filter = @(data) data; 
    end
        
    fig_filtered = plt.getFigureByName("movieSimpleMoco: Frame filtering example"); clf;
    subplot(1,2,1)
    imshow(spatial_filter(rw.h5readMovie(fullpath_movie, 'frame_start', round(sz(3)/2), 'frames_num', 1)), []);
    title("frame " + num2str(round(sz(3)/2)) + " filtered");
    drawnow;
    %%
    
    Mf = single(rw.h5readMovie(fullpath_movie)); 
    shifts = zeros([size(Mf,3),2]); 
    nan_mask = false(size(Mf, [1,2]));
%     nan_ind = [];
    for it = 1:options.niteration
        
        disp("movieSimpleMoco: finding shifts - iteration " + ...
            sprintf("%d/%d", it, options.niteration) );
        [Mf, shifts2, template] = dftMoco2(Mf,...
            'spatial_filter', spatial_filter, ...
            'upsample', options.upsample_factor*specs.binning, ...
            'max_shift', options.max_shift/specs.getPixSize());
        shifts = shifts + shifts2;

        if(options.impute_nan) 
            Mf = imputeNaNT(Mf); 

            if(any(isnan(Mf(:))))
                warning("movieSimpleMoco: constant shift")
                Mf = imputeNaNS(Mf);
            end
         else
            nan_mask = (nan_mask | any(isnan(Mf),3));
            Mf(repmat(nan_mask, [1,1,size(Mf,3)])) = 0;
        end
    end
    template(nan_mask) = NaN;
%     shifts = shifts - median(shifts,1);
    %%
      
    plt.getFigureByName("movieSimpleMoco: Frame filtering example");
    subplot(1,2,2)
    imshow(template, []); title("final template");
    %%
    
    fig_shifts = plt.getFigureByName("Shifts traces"); clf;
    plt.tracesComparison([shifts(:,1), shifts(:,2)], ...
        'nomean', false, 'labels', ["x_shift", "y_shift"], 'fps', specs.getFps());        
    %%
    
    fw = 2;
    nt = round(1*specs.getFps());
    nw = fw*nt/specs.getFps()/2;

    fig_shifts_x = plt.getFigureByName("movieSimpleMoco: Shifts traces x"); clf;
    plt.signalSpectrogram(shifts(:,1), ...
        nt, round(nt/2), nw, 'fps', specs.getFps()); sgtitle("x-shifts");
    fig_shifts_y = plt.getFigureByName("movieSimpleMoco: Shifts traces y"); clf;
    plt.signalSpectrogram(shifts(:,2), ...
        nt,round(nt/2),  nw, 'fps', specs.getFps()); sgtitle("y-shifts");
    %%
    
    M = single(rw.h5readMovie(fullpath_movie));
    M(repmat(nan_mask, [1,1,size(M,3)])) = NaN;
    
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
    disp("movieSimpleMoco: saving");
     
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
    options.illustrdir = basepath + "\illustrations\";
    options.processingdir = basepath + "\processing\movieFindMocoShifts\";
    options.diagnosticdir = basepath + "\diagnostic\movieFindMocoShifts\";
    options.bandpass = [0.0500 0.5000]; %mm
    options.max_shift = [0.5, 0.5]; %mm;
    options.upsample_factor = 20; %*specs.binning
    options.niteration = 2;
%     options.timebin = 6;

    options.impute_nan = true;
    
    options.skip = true;
end
%%
