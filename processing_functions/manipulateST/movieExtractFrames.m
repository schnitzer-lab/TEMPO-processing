function fullpath_out = movieExtractFrames(fullpath_in, frames_range, varargin)
    
    [basepath, filename, ext] = fileparts(fullpath_in);

    options = defaultOptions(basepath);
    if(~isempty(varargin))
        options = getOptions(options, varargin);
    end

    postfix_new = "_fr" + num2str(frames_range(1)) + "-" + num2str(frames_range(2));
    %%
    
    if (~isfolder(options.outdir)), mkdir(options.outdir); end

    fullpath_out = fullfile(options.outdir, filename + postfix_new + ext);
    
    if (isfile(fullpath_out))
        if(options.skip)
            displog("Output file exists. Skipping: " + fullpath_out)
            return;
        else
            warning("movieExtractFrames: Output file exists. Deleting: " + fullpath_out);
            delete(fullpath_out);
        end     
    end
    %%

    nframes = rw.h5getDatasetSize(fullpath_in, '/mov', 3);
    %%
    
    if(frames_range(2) == Inf )
       frames_range(2) = nframes;
    end
    if(frames_range(1) <= 0)
       frames_range(1) =  nframes + frames_range(1);
    end
    if(frames_range(2) <= 0)
       frames_range(2) =  nframes + frames_range(2);
    end

    if(frames_range(1) == 1 && frames_range(2) == nframes)
        if(options.outdir ~= fileparts(fullpath_in))
            fullpath_out = fullfile(options.outdir, filename + ext);
            copyfile(fullpath_in, fullpath_out);
        else 
            fullpath_out = fullpath_in;            
        end
        return;
    end
    %%
    
    displog("reading movie")
    [M, specs] = rw.h5readMovie(fullpath_in, ...
            'frames_num', frames_range(2) - frames_range(1) + 1, ...
            'frame_start', frames_range(1));
    %%
    
    specs.AddToHistory(functionCallStruct({'fullpath', 'frames_range', 'options'}));
    %%

    displog("saving")
    rw.h5saveMovie(fullpath_out, M,  specs); 
    
%     saveas(fig_trace, fullfile(options.processingdir, filename_out + "_traces.png"))
%     saveas(fig_trace, fullfile(options.processingdir, filename_out + "_traces.fig"))
end
%%

function options = defaultOptions(basepath)
    
    options.outdir = basepath;

    options.outdir = basepath;
    options.skip = true;
end
%%