function fullpath_out = movieTimeCrop(fullpath_movie, valid_range, varargin)
    
    options = defaultOptions();
    if(~isempty(varargin))
        options = getOptions(options, varargin);
    end
    %%

    [folder, file, ext] = fileparts(fullpath_movie);
    fullpath_out = fullfile(folder, file+options.postfix_new+ext );

    if (isfile(fullpath_out))
        if(options.skip)
            disp("movieTimeCrop: Output file exists. Skipping: " + fullpath_out)
            return;
        else
            warning("movieTimeCrop: Output file exists. Deleting: " + fullpath_out);
            delete(fullpath_out);
        end     
    end
    %%
    disp("movieTimeCrop: reading movie")
    [M_filtered, specs_out] = rw.h5readMovie(fullpath_movie);

    specs_out_new = copy(specs_out);
    specs_out_new.AddFrameDelay(valid_range(1)-1);
    specs_out_new.AddToHistory(functionCallStruct({'fullpath_movie', 'valid_range', 'options'}));
    
    disp("movieTimeCrop: saving")
    rw.h5saveMovie(fullpath_out, M_filtered(:,:,valid_range(1):valid_range(2)), specs_out_new);
end

function options = defaultOptions()
    options.postfix_new = '_timecrop';
    options.skip = true;
end
