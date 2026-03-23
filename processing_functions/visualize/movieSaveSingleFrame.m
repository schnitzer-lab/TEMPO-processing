function fullpath_out = movieSaveSingleFrame(fullpath_movie, varargin)
    
    [basepath, filename, ~] = fileparts(fullpath_movie);

    options = defaultOptions(basepath);
    if(~isempty(varargin))
        options = getOptions(options, varargin);
    end

    postfix_new = "_" + options.frametype;
    %%
    
    options.format = string(options.format);
    if(isempty( options.fileroot_out))
         options.fileroot_out = filename;
    end
    
    filename_out = options.fileroot_out + postfix_new + options.format;
    fullpath_out = fullfile(options.outdir, filename_out);
    
    if (isfile(fullpath_out))
        if(options.skip)
            displog("Output file exists. Skipping: " + fullpath_out)
            return;
        else
            warning("movieSaveSingleFrame: Output file exists. Deleting: " + fullpath_out);
            delete(fullpath_out);
        end     
    end

    if(~isfolder(options.outdir)), mkdir(options.outdir); end    
    %%
    
    specs = rw.h5readMovieSpecs(fullpath_movie);
    nframes = rw.h5getDatasetSize(fullpath_movie, '/mov', 3);
    if(options.frames_range(2) == Inf )
       options.frames_range(2) = nframes;
    end
    if(options.frames_range(1) <= 0)
       options.frames_range(1) =  nframes + options.frames_range(1);
    end
    if(options.frames_range(2) <= 0)
       options.frames_range(2) =  nframes + options.frames_range(2);
    end
    %%
    displog("reading movie")
    
    if(isnumeric(options.frametype))
        [frame, ~] = rw.h5readMovie(fullpath_movie, ...
            'frame_start', options.frametype, 'frames_num', 1);
    else 
        options.frametype = string(options.frametype);
        
        if (options.frametype == "F0")
            frame = []; 
            if(specs.extra_specs.isKey("expBaseline_end"))
                frame = specs.extra_specs("expBaseline_end");
            elseif(specs.extra_specs.isKey("mean_substracted")) 
                frame = specs.extra_specs.isKey("mean_substracted");
            end
    
            if(isempty(frame))
                error("No F0 found");
            end
        else
            options.frametype = string(options.frametype);
            [M, ~] = rw.h5readMovie(fullpath_movie, ...
                'frames_num', options.frames_range(2) - options.frames_range(1) + 1, ...
                'frame_start', options.frames_range(1));
            switch options.frametype
                case "mean" 
                    frame = mean(M, 3);
                case "median" 
                    frame = median(M, 3); 
                case "std" 
                    frame = std(M,[], 3);     
            end
        end
    end
    %%

    if(options.mask && ~isempty(specs.getMask()))
        nan_mask = double(specs.getMask()); nan_mask(nan_mask==0) = NaN;
        frame = frame.*nan_mask;
    end
    %%

    if(options.scalebar)
        scalebar_length = round(1/specs.getPixSize);
        scalebar_width = round(0.2*scalebar_length);
        frame(((end-scalebar_width):end)-1, (1:scalebar_length)+1) = max(frame(:));
    end
    %%

    displog("plotting and saving")
    
    plt.getFigureByName("Movie frame");
    imshow(plt.saturate(frame, options.saturate), []);
    %%
    switch options.format
        case ".bmp"
            imwrite(plt.to01(double(frame), options.saturate), fullpath_out)
        case ".h5"
            specs_out = copy(specs);
            specs_out.AddToHistory(functionCallStruct({'fullpath_movie','options'})); 
            rw.h5saveMovie(fullpath_out, frame, specs_out);
        otherwise
            error(options.format + " format unsupported, file not saved")
    end    
end
%%

function options = defaultOptions(basepath)
    
    options.outdir = fullfile(basepath, 'processing', 'singleFrame');
    options.fileroot_out = [];
    
    options.skip = true;
    options.mask = true;
    options.scalebar = true;
    options.frametype = "mean"; % "mean", "std", "median", "F0" frame number
    options.saturate = [0.02,0.98];

    options.frames_range = [1,Inf];
    
    options.format = ".bmp"; %.bmp or .h5
end
%%