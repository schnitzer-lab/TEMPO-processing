    function fullpath_out = movieCrop(fullpath_movie, box_crop, varargin)
    
    [basepath, filename, ext] = fileparts(fullpath_movie);

    options = defaultOptions(basepath);
    if(~isempty(varargin))
        options = getOptions(options, varargin);
    end
    if (~isfolder(options.diagnosticdir)) mkdir(options.diagnosticdir); end

    %%
    
    if (~isfolder(options.outdir)) mkdir(options.outdir); end

    fullpath_out = fullfile(options.outdir, filename + options.postfix_new + ext);
    
    if (isfile(fullpath_out))
        if(options.skip)
            displog("movieCrop: Output file exists. Skipping: " + fullpath_out)
            return;
        else
            warning("movieCrop: Output file exists. Deleting: " + fullpath_out);
            delete(fullpath_out);
        end     
    end
    %%    

    displog("movieCrop: reading movie")
    nframes_file = rw.h5getDatasetSize(fullpath_movie, '/mov', 3);
    [M, specs] = rw.h5readMovie(fullpath_movie, ...
        'frames_num', min(options.frames_read, nframes_file));
    %%
    
    if(isempty(box_crop))
        mask = double(specs.getMask()); mask(mask==0) = NaN;
        box_crop = mm.getCropBoxNaN(mask);
    end

    %%

    fig_crop = plt.getFigureByName("movieCrop");
    subplot(1,2,1)
    imshow(std(single(M), [], 3), []); rectangle('Position',box_crop, 'EdgeColor', 'r');    
    drawnow();
    %%    
    displog("movieCrop: cropping")
    
    M_cropped = cropMovie(M, box_crop);

    specs_out = copy(specs); 
    specs_out.AddToHistory(functionCallStruct({'fullpath_movie','box_crop','options'}));
    specs_out.AddSpatialCropping(box_crop([2,1]));
%     if(isKey(specs.extra_specs, "mask"))
%         mask_out = cropMovie(double(specs.getMask()), box_crop);
%         specs_out.extra_specs("mask") = ...
%             repelem(mask_out, specs_out.binning, specs_out.binning);
%     end
    %%

    fig_crop = plt.getFigureByName("movieCrop");
    subplot(1,2,2)
    imshow(std(single(M_cropped), [], 3), []);
    %%

    saveas(fig_crop, fullfile(options.diagnosticdir, filename + "_crop.png"))
    saveas(fig_crop, fullfile(options.diagnosticdir, filename + "_crop.fig"))
    %%
    
    displog("movieCrop: saving")
    rw.h5saveMovie(fullpath_out, M_cropped, specs_out);
    %%

    displog("movieCrop: processing chunks")
    frame_start = 1+options.frames_read;
    while frame_start < nframes_file+1
        [M, ~] = rw.h5readMovie(fullpath_movie, ...
            'frame_start', frame_start, ...
            'frames_num', min(options.frames_read, nframes_file-frame_start+1));
        M_cropped = cropMovie(M, box_crop);
        h5append(fullpath_out, M_cropped, '/mov');
        frame_start = frame_start+options.frames_read;
    end
end
%%

function options = defaultOptions(basepath)
    options.frames_read = Inf;

    options.outdir = basepath;
    options.postfix_new = "_crop";

    options.skip = true;
    options.diagnosticdir = basepath + "\diagnostic\movieCrop\";
end
%%

