function [fullpath_out_g, fullpath_out_r] =...
    moviesDecrosstalk(fullpath_movie_g, fullpath_movie_r, crosstalk, varargin)
    
    [basepath, filename_g, ext] = fileparts(fullpath_movie_g);
    [~, filename_r, ~] = fileparts(fullpath_movie_r);

    options = defaultOptions(basepath);
    if(~isempty(varargin))
        options = getOptions(options, varargin);
    end
    %%
    
    if (~isfolder(options.outdir)), mkdir(options.outdir); end
    if (~isfolder(options.processingdir)), mkdir(options.processingdir); end

    filename_out_g = filename_g + options.postfix_new;
    filename_out_r = filename_r + options.postfix_new;
    
    fullpath_out_g = fullfile(options.outdir, filename_out_g + ext);
    fullpath_out_r = fullfile(options.outdir, filename_out_r + ext);
    
    if (isfile(fullpath_out_g) && isfile(fullpath_out_r))
        if(options.skip)
            displog("Output file exists. Skipping: "  + fullpath_out_g)
            return;
        else
            warning("moviesDecrosstalk: Output file exists. Deleting: "  + fullpath_out_g);
            delete(fullpath_out_g);
            delete(fullpath_out_r);
        end     
    end
    %%
    
    displog("reading movies")
    [Mg, specs_g] = rw.h5readMovie(fullpath_movie_g);
    [Mr, specs_r] = rw.h5readMovie(fullpath_movie_r);
    %%
    
    specs_out_g = copy(specs_g);
    specs_out_g.AddToHistory(functionCallStruct(...
        {'fullpath_movie_g', 'fullpath_movie_r', 'crosstalk', 'options'}));

    specs_out_r = copy(specs_r);
    specs_out_r.AddToHistory(functionCallStruct(...
        {'fullpath_movie_g', 'fullpath_movie_r', 'crosstalk', 'options'}));
    
    displog("decrosstalking")
    decrosstalk = inv(crosstalk);
    %%
        
    Mout = decrosstalk(1,1)*Mg + decrosstalk(1,2)*Mr;
    if(decrosstalk(1,2) == 0), Mout(isnan(Mr)) = decrosstalk(1,1)*Mg(isnan(Mr)); end
   
    fig_trace_g = plt.getFigureByName("moviesDecrosstalk: Traces comparison G");
    plt.tracesComparison([squeeze(mean(Mg, [1,2],'omitnan' )), squeeze(mean(Mout, [1,2],'omitnan'))], ...
        'fps', specs_g.getFps(), 'fw', 0.2, 'labels', ["spatially-averaged trace", "spatially-averaged trace after decrosstalking"]) 
    sgtitle({basepath, filename_g}, 'interpreter', 'none', 'FontSize', 10); 
    drawnow();
    %%
    
    rw.h5saveMovie(fullpath_out_g, Mout, specs_out_g);
    %%
    
    Mout = decrosstalk(2,2)*Mr + decrosstalk(2,1)*Mg;
    if(decrosstalk(2,1) == 0), Mout(isnan(Mg)) = decrosstalk(2,2)*Mr(isnan(Mg)); end
       
    fig_trace_r = plt.getFigureByName("moviesDecrosstalk: Traces comparison R");
    plt.tracesComparison([squeeze(mean(Mr, [1,2],'omitnan' )), squeeze(mean(Mout, [1,2],'omitnan'))], ...
        'fps', specs_g.getFps(), 'fw', 0.2,...
        'labels', ["spatially-averaged trace", "spatially-averaged trace after decrosstalking"]) 
    sgtitle({basepath, filename_r}, 'interpreter', 'none', 'FontSize', 10); 
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
 
    options.processingdir = fullfile(basepath, 'diagnostic', 'decrosstalk');
    options.postfix_new = "_decross";
    options.outdir = basepath;
    options.skip = true;
end
%%