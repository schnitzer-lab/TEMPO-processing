function moviesSavePreviewVideos(fullpaths_movies, varargin)
    %%

    [basepath, filename, ~] =  fileparts(fullpaths_movies(1));

    options = defaultOptions(basepath);
    if(~isempty(varargin))
        options = getOptions(options, varargin);
    end
    %%
    
    if (~isfolder(options.outdir)), mkdir(options.outdir); end

    if(~iscell(options.ranges)), options.ranges = {options.ranges}; end
    if(isempty(options.postfixes)) 
        if(isempty(options.ranges))
            options.postfixes = ["_begin", "_end"]; 
        else
            for i_r = 1:length(options.ranges) 
                options.postfixes(i_r) = ...
                    "_"+string(min(options.ranges{i_r}))+"-"+string(max(options.ranges{i_r}))  ;
            end
        end
    end
    if(isempty(options.titles))
        options.titles = string(1:length(fullpaths_movies));
    end

    if(length(fullpaths_movies) > 1), options.postfixes = "_combined" + options.postfixes ; end
    fullpaths_out = fullfile(options.outdir, filename) + options.postfixes +".avi";

    if (options.skip && all(isfile(fullpaths_out)) )
        displog("Output files exist. Skipping: " + fullpaths_out(1));
        return;
    end
    %%
    
    displog("reading movie")
   
    Ms = cell(length(fullpaths_movies), 1);
    Ss = cell(length(fullpaths_movies), 1);

    for i_f = 1:length(fullpaths_movies)
        [M, specs] = rw.h5readMovie(fullpaths_movies(i_f));
        Ms{i_f} = M;
        Ss{i_f} = specs;
    end
    %%

    timeorigin = max(cellfun(@(s) s.timeorigin, Ss));
    nframes = min(cellfun(@(M) size(M,3), Ms));

    for i_f = 1:length(fullpaths_movies)
        Ms{i_f} = double(Ms{i_f}(:,:,(timeorigin-Ss{i_f}.timeorigin+1):(timeorigin-Ss{i_f}.timeorigin+nframes)));
        Ss{i_f}.AddFrameDelay(timeorigin-Ss{i_f}.timeorigin);

        if(options.mask && ~isempty(Ss{i_f}.getMask()))
            Ms{i_f} = Ms{i_f}.*specs.getMaskNaN(size(Ms{i_f},[1,2]));
        end
    end

    ttl_signal = Ss{1}.getTTLTrace(nframes); 
    if(isempty(ttl_signal)), ttl_signal = zeros(nframes,1); end
    %%
    
    displog("saving video")
   
    options.slowdown = options.slowdown/options.upsample_t;
    options_saveavi = ...
        struct('fps', specs.getFps()/options.slowdown, ...
        'colormap', options.colormap, 'overwrite', true, ...
        'nancolor', options.nancolor, 'textcolor', options.textcolor);
    
    if(isempty(options.ranges))
        nframes_save = round(options.nseconds*specs.getFps());
        range_begin = (1:(1+nframes_save))+(timeorigin-1); %from 1 case plt.addMovieHeader takes care of frame0
        range_end = ((nframes-nframes_save):nframes)+(timeorigin-1);
        options.ranges = {range_begin, range_end};
    end

    upsample_s = max(round(150/size(M,1)), 1);

    sc_ratios = ones(length(Ms), 1);
    if(~options.scale)
        stds = cellfun(@(M) std(M(:), 'omitnan'), Ms);
        sc_ratios = stds / max(stds);
    end

    % header/footer background takes the nan color when nancolor is set
    bg_value = 0; if(~isempty(options.nancolor)), bg_value = NaN; end
    % header/footer text is marked +Inf and drawn in textcolor by SaveAVI
    text_args = {};
    if(~isempty(options.textcolor)), text_args = {'text_value', Inf}; end

    center = @(movie) movie - (max(movie, [], 'all', 'omitnan')+min(movie, [], 'all', 'omitnan'))/2;

    movietosave = @(M, r, title, sc) ...
        plt.addMovieHeader( ...
            center( ...
                repelem( ...
                    plt.to01( ...
                        upsampleTime(M(:,:, r), options.upsample_t), ...
                    options.saturate) * sc - 0.5, ...
                upsample_s, upsample_s)),...
        'fps', specs.getFps(), 'pxsize', specs.getPixSize()/upsample_s,...
        'title', title, 'background_value', bg_value, text_args{:}, ...
        'frame0', r(1)+timeorigin-1, 'dframe', specs.timebinning/options.upsample_t,...
        'extra_labels', repelem(ttl_signal(r), options.upsample_t,1));

    for i_r = 1:length(options.ranges)

        SaveAVI( ...
            plt.catMoviesSpaced( ...
                    cellfun( ...
                        @(i_M) movietosave(Ms{i_M}, options.ranges{i_r}-(timeorigin-1), options.titles(i_M), sc_ratios(i_M)), ...
                        num2cell(1:length(Ms)), 'UniformOutput', false), ...
                2, 'value', bg_value), ...
            fullpaths_out(i_r), options_saveavi)
    end
end
%%

function M = upsampleTime(M, upsample_t)
% the movie M upsampled in time by the factor upsample_t (integer), NaN
% tolerant: interpft (as before) on the pixels without NaN, linear
% interpolation on the pixels with some NaN samples, so that a NaN sample
% does not make the whole trace NaN (interpft is an FFT). No interpolation
% for upsample_t = 1

    if(upsample_t == 1), return; end

    [nx, ny, nt] = size(M);
    nt_out = nt*upsample_t;
    M = reshape(M, nx*ny, nt);
    hasNaN = any(isnan(M), 2);

    M_out = nan(nx*ny, nt_out);
    if(any(~hasNaN))
        M_out(~hasNaN,:) = interpft(M(~hasNaN,:), nt_out, 2);
    end
    % the sample times of interpft: the original samples at 1:upsample_t:end;
    % the last upsample_t-1 samples are past nt (extrapolated)
    if(any(hasNaN))
        t_out = 1 + (0:nt_out-1)/upsample_t;
        M_out(hasNaN,:) = interp1(1:nt, M(hasNaN,:)', t_out, 'linear', 'extrap')';
    end
    M = reshape(M_out, nx, ny, nt_out);
end
%%

function options = defaultOptions(basepath)
    
    options.outdir = fullfile(basepath, 'illustrations');
    options.skip = true;

    options.mask = true;

    options.scale = true; % if false, movies are displayed with relative brightness proportional to their std (max-std movie fills 0-1, others dimmed by std/std_max), instead of each independently stretched to full contrast
    
    options.titles = [];

    options.colormap = plt.redblue(256); % nx3 colormap matrix

    options.nancolor = [1 1 1]; % rgb (0-1) for all nan pixels (mask etc.)
    options.textcolor = [0 0 0]; % rgb (0-1) for header/footer text

    options.nseconds = 10;
    options.saturate = 0.03;
    options.slowdown = 5;
    options.upsample_t = 1;

    options.ranges = {};
    options.postfixes = string([]);
end
%%