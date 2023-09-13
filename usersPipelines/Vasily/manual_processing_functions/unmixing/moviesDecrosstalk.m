function [fullpath_out_g, fullpath_out_r] =...
    moviesDecrosstalk(fullpath_movie_g, fullpath_movie_r, crosstalk, varargin)
    
    [basepath, basefilename_g, ext, postfix_g] = filenameSplit(fullpath_movie_g, '_');
    [~, basefilename_r, ~, postfix_r] = filenameSplit(fullpath_movie_r, '_');

    options = defaultOptions(basepath);
    if(~isempty(varargin))
        options = getOptions(options, varargin);
    end

    postfix_new = "_decross";
    %%
    
    if (~isfolder(options.outdir)) mkdir(options.outdir); end
    if (~isfolder(options.processingdir)) mkdir(options.processingdir); end

    filename_out_g = basefilename_g + postfix_g + postfix_new;
    filename_out_r = basefilename_r + postfix_r + postfix_new;
    
    fullpath_out_g = fullfile(options.outdir, filename_out_g + ext);
    fullpath_out_r = fullfile(options.outdir, filename_out_r + ext);
    
    if (isfile(fullpath_out_g) && isfile(fullpath_out_r))
        if(options.skip)
            disp("moviesDecrosstalk: Output file exists. Skipping: "  + fullpath_out_g)
            return;
        else
            warning("moviesDecrosstalk: Output file exists. Deleting: "  + fullpath_out_g);
            delete(fullpath_out_g);
            delete(fullpath_out_r);
        end     
    end
    %%
    
    disp("moviesDecrosstalk: reading movies")
    [Mg, specs_g] = rw.h5readMovie(fullpath_movie_g);
    [Mr, specs_r] = rw.h5readMovie(fullpath_movie_r);
    %%
    
    specs_out_g = copy(specs_g);
    specs_out_g.AddToHistory(functionCallStruct(...
        {'fullpath_movie_g', 'fullpath_movie_r', 'crosstalk', 'options'}));

    specs_out_r = copy(specs_r);
    specs_out_r.AddToHistory(functionCallStruct(...
        {'fullpath_movie_g', 'fullpath_movie_r', 'crosstalk', 'options'}));
    
    disp("moviesDecrosstalk: decrosstalking")
    decrosstalk = inv(crosstalk);
    %%
    
    
    Mout = decrosstalk(1,1)*Mg + decrosstalk(1,2)*Mr;
    
    d = abs(options.framedelay);
    if(options.framedelay >= 0)
        Mout(:,:,1:(end-d)) = decrosstalk(1,1)*Mg(:,:, 1:(end-d)) + decrosstalk(1,2)*Mr(:,:,(1+d):end);
    else
        Mout(:,:,(1+d):end) = decrosstalk(1,1)*Mg(:,:,(1+d):end) + decrosstalk(1,2)*Mr(:,:, 1:(end-d));
    end
    
    fig_trace_g = plt.getFigureByName("moviesDecrosstalk: Traces comparison G");
    plt.tracesComparison([squeeze(mean(Mg, [1,2],'omitnan' )), squeeze(mean(Mout, [1,2],'omitnan'))], ...
        'fps', specs_g.fps, 'labels', ["spatially-averaged trace", "spatially-averaged trace after decrosstalking"]) 
    sgtitle({basepath, basefilename_g + postfix_g}, 'interpreter', 'none', 'FontSize', 10); 
    drawnow();
    %%
    
    rw.h5saveMovie(fullpath_out_g, Mout, specs_out_g);
    %%
    
    Mout = decrosstalk(2,2)*Mr + decrosstalk(2,1)*Mg;
    
    d = abs(options.framedelay);
    if(options.framedelay >= 0)
        Mout(:,:,1:(end-d)) = decrosstalk(2,1)*Mg(:,:, 1:(end-d)) + decrosstalk(2,2)*Mr(:,:,(1+d):end);
    else
        Mout(:,:,(1+d):end) = decrosstalk(2,1)*Mg(:,:,(1+d):end) + decrosstalk(2,2)*Mr(:,:, 1:(end-d));
    end
    
    fig_trace_r = plt.getFigureByName("moviesDecrosstalk: Traces comparison R");
    plt.tracesComparison([squeeze(mean(Mr, [1,2],'omitnan' )), squeeze(mean(Mout, [1,2],'omitnan'))], ...
        'fps', specs_g.fps, 'nw', 15,...
        'labels', ["spatially-averaged trace", "spatially-averaged trace after decrosstalking"]) 
    sgtitle({basepath, basefilename_r + postfix_r}, 'interpreter', 'none', 'FontSize', 10); 
    drawnow();
    %%
    
    rw.h5saveMovie(fullpath_out_r, Mout, specs_out_r);
    %%

    saveas(fig_trace_g, fullfile(options.processingdir, filename_out_g + "_decrosstalking.png"))
    saveas(fig_trace_g, fullfile(options.processingdir, filename_out_g + "_decrosstalking.fig"))
    saveas(fig_trace_r, fullfile(options.processingdir, filename_out_r + "_decrosstalking.png"))
    saveas(fig_trace_r, fullfile(options.processingdir, filename_out_r + "_decrosstalking.fig"))
end
%%

function options = defaultOptions(basepath)
 
    options.processingdir = basepath + "\diagnostic\decrosstalk\";
    options.outdir = basepath;
    options.skip = true;
    options.framedelay = 0;
end
%%