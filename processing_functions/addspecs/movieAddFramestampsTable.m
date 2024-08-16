function fullpath_movie = movieAddFramestampsTable(fullpath_movie, varargin)
    
    [basepath, basefilename, ext, postfix] = filenameSplit(fullpath_movie, '_');

    options = defaultOptions(basepath);
    if(~isempty(varargin))
        options = getOptions(options, varargin);
    end

    %%
    
    if(rw.h5checkDatasetExists(fullpath_movie, '/specs/extra_specs/timestamps_table') && ...
       rw.h5checkDatasetExists(fullpath_movie, '/specs/extra_specs/timestamps_table_names') && ...
       options.skip)
        warning("timestamps_table already added, skipping: " + fullpath_movie)
        return;
    end

    timestamps_filestruct = dir(fullfile(basepath, "LVMeta", "*cG_framestamps 0.txt"));
    
    if(~isempty(timestamps_filestruct))
        metadata_t = readtable(fullfile(timestamps_filestruct.folder, timestamps_filestruct.name));
        
        if(isempty(metadata_t))
            warning("timestamps file empty");
        else
            h5save(fullpath_movie, table2array(metadata_t), ...
                '/specs/extra_specs/timestamps_table');
            h5save(fullpath_movie, strjoin(metadata_t.Properties.VariableNames, ';'), ...
                '/specs/extra_specs/timestamps_table_names');
        end
    else
        warning("ususal timestamps file not found");
    end
end
%%

function options = defaultOptions(basepath)
%     options = [];
    options.skip = true;
end
%%