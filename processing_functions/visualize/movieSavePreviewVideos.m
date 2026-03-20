function fullpaths_out = movieSavePreviewVideos(fullpath_movie, varargin)
    
    [basepath, filename, ~, ~] = ...
        filenameSplit(fullpath_movie);

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
        displog("Output files exist. Skipping: " + fullpaths_out(1));
        return;
    end
    %%
    
    displog("reading movie")
   
    specs = rw.h5readMovieSpecs(fullpath_movie);
    [nx,nt] = rw.h5getDatasetSize(fullpath_movie, '/mov', [1,3]);
    
    ttl_signal = specs.getTTLTrace(nt);
    if(isempty(ttl_signal)), ttl_signal = zeros(nt,1); end
    if(isempty(options.upsample_s))
        options.upsample_s = max(round(150/nx), 1);
    end
    %%
 
    displog("saving video")
   
    options.slowdown = options.slowdown/options.upsample_t;
    options_saveavi = ...
        struct('fps', specs.getFps()/options.slowdown, ...
            'colormap', options.colormap, 'overwrite', true);

    nframes = min(round(options.nseconds*specs.getFps()), nt-1);
    
    if(isempty(options.ranges))
        range_begin = (1:(1+nframes))+(specs.timeorigin-1);
        range_end = ((nt-nframes):nt)+(specs.timeorigin-1);
        options.ranges = {range_begin, range_end};

        if(nframes == nt-1), options.ranges = {range_begin}; end
    end

    pixsize = specs.getPixSize(); if(isnan(pixsize)), pixsize = []; end

    center = @(movie) movie - (max(movie, [], 'all', 'omitnan')+min(movie, [], 'all', 'omitnan'))/2;
    movietosave = @(M, range) ...
        plt.addMovieHeader(( ...
            repelem( ... %
                center(plt.saturate(M, ...%M(:,:, range)
                            options.saturate)), ...
                options.upsample_s, options.upsample_s)),...
        'fps', specs.getFps()*specs.timebinning, 'pxsize', pixsize,...
        'title', options.title, 'background_value', 0, ...
        'frame0', range(1)+specs.timeorigin-1, 'dframe', specs.timebinning,...
        'extra_labels', ttl_signal(range));
    
    for i_r = 1:length(options.ranges)
        
        frames_range = options.ranges{i_r}-(specs.timeorigin-1);

        M_tosave = rw.h5readMovie(fullpath_movie, ...
            'frame_start', frames_range(1), ...
            'frames_num', frames_range(end)-frames_range(1)+1);
        if(options.mask && ~isempty(specs.getMask()))
            M_tosave = M_tosave.*specs.getMaskNaN(size(M_tosave,[1,2]));
        end

        if(options.flip_x), M_tosave = flip(M_tosave, 2); end
        if(options.flip_y), M_tosave = flip(M_tosave); end

        M_tosave = movietosave(double(M_tosave), frames_range);

        if(options.upsample_t ~= 1)
            nt_out = round(size(M_tosave, 3)*options.upsample_t);
            
            if(mod(options.upsample_t, 1) == 0)
                M_tosave = interpft(M_tosave, nt_out, 3);
            else
                M_tosave = permute(interp1(...
                    linspace(1, size(M_tosave,3), size(M_tosave,3)), ...
                    permute(M_tosave, [3,1,2]), ...
                    linspace(1, size(M_tosave,3), nt_out)),...
                    [2,3,1]);
            end
        end
        
        SaveAVI(M_tosave, fullpaths_out(i_r), options_saveavi)
    end
end
%%

function options = defaultOptions(basepath)
    
    options.outdir = fullfile(basepath, 'illustrations');
    options.skip = true;
    
    options.title = '';
    
    options.nseconds = 10;
    options.saturate = 0.03;
    options.slowdown = 5;
    options.upsample_t = 1;
    options.upsample_s = [];

    options.flip_x = false;
    options.flip_y = false;

    options.mask = false;

    options.colormap = plt.redblue(256);

    options.ranges = {};
    options.postfixes = string([]);
end
%%