function fullpath_movie = movieAddTimestampsTable(fullpath_movie, varargin)
    
    
    [basepath, basefilename, ext, postfix] = ...
        filenameSplit(fullpath_movie, '-c', true);

    options = defaultOptions(basepath);
    if(~isempty(varargin))
        options = getOptions(options, varargin);
    end

    %%
    
    if(rw.h5checkDatasetExists(fullpath_movie, options.dataset) && options.skip)
        warning("timestamps already added, skipping: " + fullpath_movie)
    end
    
    timestamps_filename = ...
        fullfile(basepath, "LVMeta", basefilename + extractBetween(postfix, 1,1) + ".dcimg.txt");
    
    if(isfile(timestamps_filename))      
        metadata_t = readmatrix(timestamps_filename, 'Delimiter', '\t');
        if(options.droplast) metadata_t = metadata_t(1:(end-1)); end
        
        h5save(fullpath_movie, metadata_t, options.dataset);
    else
        warning("ususal timestamps file not found");
    end
end
%%

function options = defaultOptions(basepath)
    options.droplast = true;
    options.skip = true;
    options.dataset = '/specs/extra_specs/timestamps';
end
%%