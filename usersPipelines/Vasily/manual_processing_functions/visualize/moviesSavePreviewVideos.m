function moviesSavePreviewVideos(fullpaths_movies, varargin)
    %%

    [basepath, filename, ext, basefilename, channel, postfix] = ...
        filenameParts(fullpaths_movies(1));

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
    if(isempty(options.titles))
        options.titles = string(1:length(fullpaths_movies));
    end

    if(length(fullpaths_movies) > 1) options.postfixes = "_combined" + options.postfixes ; end
    fullpaths_out = fullfile(options.outdir, filename) + options.postfixes +".avi";

    if (options.skip && all(isfile(fullpaths_out)) )
        disp("movieSavePreviewVideos: Output files exist. Skipping: " + fullpaths_out(1));
        return;
    end
    %%
    
    disp("movieSavePreviewVideos: reading movie")
   
    Ms = cell(length(fullpaths_movies), 1);
    Ss = cell(length(fullpaths_movies), 1);;

    for i_f = 1:length(fullpaths_movies);
        [M, specs] = rw.h5readMovie(fullpaths_movies(i_f));
        Ms{i_f} = M;
        Ss{i_f} = specs;
    end
    %%

    timeorigin = max(cellfun(@(s) s.timeorigin, Ss));
    nframes = min(cellfun(@(M) size(M,3), Ms));

    for i_f = 1:length(fullpaths_movies)
        Ms{i_f} = Ms{i_f}(:,:,(timeorigin-Ss{i_f}.timeorigin+1):(timeorigin-Ss{i_f}.timeorigin+nframes));
        Ss{i_f}.AddFrameDelay(timeorigin-Ss{i_f}.timeorigin);
    end

    ttl_signal = Ss{1}.getTTLTrace(nframes); 
    if(isempty(ttl_signal)) ttl_signal = zeros(nframes,1); end
    %%
    
    disp("movieSavePreviewVideos: saving video")
   
    options.slowdown = options.slowdown/options.upsample_t;
    options_saveavi = ...
        struct('fps', specs.getFps()/options.slowdown, 'colormap', plt.redblue, 'overwrite', true);
    
    if(isempty(options.ranges))
        nframes_save = round(options.nseconds*specs.getFps());
        range_begin = (1:(1+nframes_save))+(timeorigin-1); %from 1 case plt.addMovieHeader takes care of frame0
        range_end = ((nframes-nframes_save):nframes)+(timeorigin-1);
        options.ranges = {range_begin, range_end};
    end

    upsample_s = max(round(150/size(M,1)), 1);

    center = @(movie) movie - (max(movie, [], 'all', 'omitnan')+min(movie, [], 'all', 'omitnan'))/2;
    
    movietosave = @(M, r, title) ...
        plt.addMovieHeader( ...
            center( ...
                repelem( ...
                    plt.to01( ...
                        interpft(...
                            M(:,:, r), ...
                        length(r)*options.upsample_t,3), ...
                    options.saturate) - 0.5, ...
                upsample_s, upsample_s)),...
        'fps', specs.getFps(), 'pxsize', specs.getPixSize(),...
        'title', title, 'background_value', 0, ...
        'frame0', r(1)+timeorigin-1, 'dframe', specs.timebinning/options.upsample_t,...
        'extra_labels', repelem(ttl_signal(r), options.upsample_t,1));
    
    for i_r = 1:length(options.ranges)
        
        SaveAVI( ...
            plt.catMoviesSpaced( ...
                    cellfun( ...
                        @(i_M) movietosave(Ms{i_M}, options.ranges{i_r}-(timeorigin-1), options.titles(i_M)), ...
                        num2cell(1:length(Ms)), 'UniformOutput', false), ...
                2), ...
            fullpaths_out(i_r), options_saveavi)
    end
end
%%

function options = defaultOptions(basepath)
    
    options.outdir = basepath + "\illustrations\";
    options.skip = true;
    
    options.titles = [];
    
    options.nseconds = 10;
    options.saturate = 0.03;
    options.slowdown = 5;
    options.upsample_t = 1;

    options.ranges = {};
    options.postfixes = string([]);
end
%%