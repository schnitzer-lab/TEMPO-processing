function fullpath_movie = movieAddTimestampsTable(fullpath_movie, varargin)
    
    
    [basepath, ~, ~] = fileparts(fullpath_movie, '-c', true);

    options = defaultOptions();
    if(~isempty(varargin))
        options = getOptions(options, varargin);
    end
    %%
    
    if(rw.h5checkDatasetExists(fullpath_movie, options.dataset) && options.skip)
        warning("timestamps already added, skipping: " + fullpath_movie)
    end
    
    fname_pattern = fullfile(basepath, "LVMeta", "*-c"+specs.channel_id+".dcimg.txt");
    file = dir(fname_pattern);
    
    if (isempty(file)) 
        error("movieAddTimestampsTable: no timestamp file " + fname_pattern);
    elseif (length(file) > 1)
        error("movieAddTimestampsTable: more than one timestamp file " + fname_pattern); 
    end

    timestamps_filename = fullfile(file.folder, file.name);
    
    if(isfile(timestamps_filename))      
        metadata_t = readmatrix(timestamps_filename, 'Delimiter', '\t');
        if(options.droplast), metadata_t = metadata_t(1:(end-1)); end
        
        h5save(fullpath_movie, metadata_t, options.dataset);
    else
        warning("ususal timestamps file not found");
    end
end
%%

function options = defaultOptions()
    options.droplast = true;
    options.skip = true;
    options.dataset = '/specs/extra_specs/timestamps';
end
%%