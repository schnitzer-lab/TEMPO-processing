function fullpath_out = movieSaveSingleFrame(fullpath_movie, varargin)
    
    [basepath, basefilename, ext, postfix] = filenameSplit(fullpath_movie, '_');

    options = defaultOptions(basepath);
    if(~isempty(varargin))
        options = getOptions(options, varargin);
    end

    postfix_new = "_" + options.frametype;
    %%
    
    options.format = string(options.format);
    if(isempty( options.fileroot_out))
         options.fileroot_out = basefilename + postfix;
    end
    
    filename_out = options.fileroot_out + postfix_new + options.format;
    fullpath_out = fullfile(options.outdir, filename_out);
    
    if (isfile(fullpath_out))
        if(options.skip)
            disp("movieSaveSingleFrame: Output file exists. Skipping: " + fullpath_out)
            return;
        else
            warning("movieSaveSingleFrame: Output file exists. Deleting: " + fullpath_out);
            delete(fullpath_out);
        end     
    end

    if(~isfolder(options.outdir)) mkdir(options.outdir); end    
    %%
    disp("movieSaveSingleFrame: reading movie")
    
    if(isnumeric(options.frametype))
        [frame, ~] = rw.h5readMovie(fullpath_movie, ...
            'frame_start', options.frametype, 'frames_num', 1);
    else
        options.frametype = string(options.frametype);
        switch options.frametype
            case "mean" 
                [M, specs] = rw.h5readMovie(fullpath_movie);
                frame = mean(M, 3);
            case "median" 
                [M, specs] = rw.h5readMovie(fullpath_movie);    
                frame = median(M, 3); 
            case "std" 
                [M, specs] = rw.h5readMovie(fullpath_movie);
                frame = std(M,[], 3); 
            case "F0" 
                specs = rw.h5readMovieSpecs(fullpath_movie);
                frame = []; 
                if(specs.extra_specs.isKey("expBaseline_A"))
                    frame = specs.extra_specs("expBaseline_A");
                elseif(specs.extra_specs.isKey("mean_substracted")) 
                    frame = specs.extra_specs.isKey("mean_substracted");
                end
        
                if(isempty(frame))
                    error("No F0 found");
                end
        end
    end
    %%

    specs = rw.h5readMovieSpecs(fullpath_movie);
    if(options.mask && ~isempty(specs.getMask()))
        nan_mask = double(specs.getMask()); nan_mask(nan_mask==0) = NaN;
        frame = frame.*nan_mask;
    end
    %%

    disp("movieSaveSingleFrame: plotting and saving")
    
    plt.getFigureByName("Movie frame");
    imshow(plt.saturate(frame, options.saturate), []);

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
    
    options.outdir = basepath;
    options.fileroot_out = [];
    
    options.skip = true;
    options.mask = true;
    options.frametype = "mean"; % "mean", "std", "median", "F0" frame number
    options.saturate = [0.02,0.98];
    
    options.format = ".bmp"; %.bmp or .h5
end
%%