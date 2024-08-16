function maskfullpath_out = movieMakeMask(fullpath_g, varargin)
    
    [basepath, basefilename, ~, postfix] = filenameSplit(fullpath_g, '_');

    options = defaultOptions(basepath);
    if(~isempty(varargin))
        options = getOptions(options, varargin);
    end

    postfix_new = "_mask";
    %%
    
    if (~isfolder(options.outdir)) mkdir(options.outdir); end
    if (~isfolder(options.processingdir)) mkdir(options.processingdir); end

    maskfilename_out = basefilename + postfix + postfix_new;
    maskfullpath_out = fullfile(options.outdir, maskfilename_out + options.ext);
    meanfullpath_out = fullfile(options.outdir, maskfilename_out + 'mean' + options.ext);
    
    disp("movieMakeMask: reading movie")
    [M, ~] = rw.h5readMovie(fullpath_g);
    
    %%

    
    disp("movieMakeMask: computing the mask")
    Mmean = median(M,3, 'omitnan');
    Mmean(isnan(Mmean)) = 0;
    mask = mm.getImageMask(Mmean, ...
        copyStruct(options, {'thres', 'dog_sdfrac', 'sm_sdfrac', 'edgeq0'} ));
    
    fig = plt.getFigureByName("Masked movie");
    imshow(Mmean.*mask, []); 
    drawnow();
    
    %%
    disp("movieMakeMask: Saving")
    
    imwrite(mat2gray(mask), maskfullpath_out);
    imwrite(mat2gray(Mmean), meanfullpath_out);
    
    imwrite(mat2gray(Mmean), fullfile(options.processingdir, maskfilename_out + "_mean" + options.ext));
    
    saveas(fig, fullfile(options.processingdir, maskfilename_out + "_mean_masked" + ".png"))
    saveas(fig, fullfile(options.processingdir, maskfilename_out + "_mean_masked" + ".fig"))
end
%%

function options = defaultOptions(basepath)
    
    options.thres = 0.5;
    options.dog_sdfrac = 0.005;
    options.sm_sdfrac = 0.02;
    options.edgeq0 = 0.5;
    
    
    options.processingdir = basepath + "\diagnostic\makeMask\";
    options.outdir = basepath + "\alignment_images\";
    
    options.ext = ".bmp";
end
%%

function saveVideos(Mg, illustrdir, filename_out, fps, nframes, slowdown)

    SaveAVI(Mg(:,:, 1:nframes) ,...
        char(fullfile(illustrdir, filename_out + '_' + num2str(slowdown) + 'xslow_begin')), ...
        'quantile', 0.98, 'fps', fps, 'overwrite', true)
    SaveAVI(Mg(:,:, (end-nframes+1):end),...
        char(fullfile(illustrdir, filename_out + '_' + num2str(slowdown) + 'xslow_end')), ...
        'quantile', 0.98, 'fps', fps, 'overwrite', true)
end
