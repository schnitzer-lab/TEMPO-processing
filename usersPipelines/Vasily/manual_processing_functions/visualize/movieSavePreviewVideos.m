function movieSavePreviewVideos(fullpath_movie, varargin)
    
    [basepath, filename, ext, basefilename, channel, postfix] = ...
        filenameParts(fullpath_movie);

    options = defaultOptions(basepath);
    if(~isempty(varargin))
        options = getOptions(options, varargin);
    end
    %%
    
    if (~isfolder(options.outdir)) mkdir(options.outdir); end

    if(~iscell(options.ranges)) options.ranges = {options.ranges}; end
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

    fullpaths_out = fullfile(options.outdir, filename) + options.postfixes + ".avi";
%     fullpath_out_begin = fullfile(options.outdir, filename)+ "_begin.avi";
%     fullpath_out_end = fullfile(options.outdir, filename)+ "_end.avi";
    
    if (options.skip && all(isfile(fullpaths_out)) )
        disp("movieSavePreviewVideos: Output files exist. Skipping: " + fullpaths_out(1));
        return;
    end
    %%
    
    disp("movieSavePreviewVideos: reading movie")
   
    [M, specs] = rw.h5readMovie(fullpath_movie);

    ttl_signal = specs.getTTLTrace(size(M,3));
    if(isempty(ttl_signal)) ttl_signal = zeros(size(M,3),1); end
    %%
    
    if(options.mask && ~isempty(specs.getMask()))
        mask = double(specs.getMask(size(M,[1,2])));
        mask(~mask) = NaN;
        M = M.*repmat(mask, [1,1,size(M,3)]);
    end
    %%

    disp("movieSavePreviewVideos: saving video")
   
    options.slowdown = options.slowdown/options.upsample_t;
    options_saveavi = ...
        struct('fps', specs.getFps()/options.slowdown, 'colormap', plt.redblue, 'overwrite', true);

    nframes = round(options.nseconds*specs.getFps());
    
    if(isempty(options.ranges))
        range_begin = (1:(1+nframes))+(specs.timeorigin-1);
        range_end = ((size(M,3)-nframes):size(M,3))+(specs.timeorigin-1);
        options.ranges = {range_begin, range_end};
    end

    upsample_s = max(round(150/size(M,1)), 1);

    center = @(movie) movie - (max(movie, [], 'all', 'omitnan')+min(movie, [], 'all', 'omitnan'))/2;
    movietosave = @(range) ...
        plt.addMovieHeader((repelem( ... %
                center(plt.saturate(interpft(M(:,:, range), ...
            length(range)*options.upsample_t,3), options.saturate)), upsample_s, upsample_s)),...
        'fps', specs.getFps(), 'pxsize', specs.getPixSize(),...
        'title', options.title, 'background_value', 0, ...
        'frame0', range(1)+specs.timeorigin-1, 'dframe', specs.timebinning/options.upsample_t,...
        'extra_labels', repelem(ttl_signal(range), options.upsample_t,1));
    
    for i_r = 1:length(options.ranges)
        SaveAVI(movietosave(options.ranges{i_r}-(specs.timeorigin-1)), fullpaths_out(i_r), options_saveavi)
    end
end
%%

function options = defaultOptions(basepath)
    
    options.outdir = basepath + "\illustrations\";
    options.skip = true;
    
    options.title = '';
    
    options.nseconds = 10;
    options.saturate = 0.03;
    options.slowdown = 5;
    options.upsample_t = 1;

    options.mask = false;

    options.ranges = {};
    options.postfixes = string([]);
end
%%