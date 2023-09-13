function fullpath_out = movieExtractFrames(fullpath, frames_range, varargin)
    
    [basepath, basefilename, ext, postfix] = filenameSplit(fullpath, '_');

    options = defaultOptions(basepath);
    if(~isempty(varargin))
        options = getOptions(options, varargin);
    end

    postfix_new = "_fr" + num2str(frames_range(1)) + "-" + num2str(frames_range(2));
    %%
    
    if (~isfolder(options.outdir)) mkdir(options.outdir); end

    filename_out = basefilename + postfix + postfix_new;
    fullpath_out = fullfile(options.outdir, filename_out + ext);
    
    if (isfile(fullpath_out))
        if(options.skip)
            disp("movieExtractFrames: Output file exists. Skipping: " + fullpath_out)
            return;
        else
            warning("movieExtractFrames: Output file exists. Deleting: " + fullpath_out);
            delete(fullpath_out);
        end     
    end
    %%
    
    if(frames_range(2) == Inf )
       frames_range(2) = 0;
    end
 
    if(frames_range(2) <= 0)
       frames_range(2) =  rw.h5getDatasetSize(fullpath, '/mov', 3) + frames_range(2);
    end
    %%
    disp("movieExtractFrames: reading movie")
    [M, specs] = rw.h5readMovie(fullpath, ...
            'frames_num', frames_range(2) - frames_range(1) + 1, ...
            'frame_start', frames_range(1));
    %%
    
    specs.AddToHistory(functionCallStruct({'fullpath', 'frames_range', 'options'}));
    %%
    disp("movieExtractFrames: saving")
    rw.h5saveMovie( fullpath_out, M,  specs); 
    
%     saveas(fig_trace, fullfile(options.processingdir, filename_out + "_traces.png"))
%     saveas(fig_trace, fullfile(options.processingdir, filename_out + "_traces.fig"))
end
%%

function options = defaultOptions(basepath)
    
    options.outdir = basepath;
    options.skip = true;
end
%%