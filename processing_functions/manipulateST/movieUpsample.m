function fullpath_out = movieUpsample(fullpath_movie, n_x, n_y,  varargin)
    
    [basepath, filename, ext] = fileparts(fullpath_movie);

    options = parseInputs(basepath, varargin{:});
    %%
    
    if (~isfolder(options.outdir)), mkdir(options.outdir); end
    if (~isfolder(options.diagnosticdir)), mkdir(options.diagnosticdir); end

    filename_out = filename+options.postfix_new;
    fullpath_out = fullfile(options.outdir, filename_out + ext);
    
    if (isfile(fullpath_out))
        if(options.skip)
            displog("movieTemplateFunction: Output file exists. Skipping: " + fullpath_out)
            return;
        else
            warning("movieTemplateFunction: Output file exists. Deleting: " + fullpath_out);
            delete(fullpath_out);
        end     
    end
    %%
    
    displog("movieUpsample: reading movie")
    [M, specs] = rw.h5readMovie(fullpath_movie);
    %%

    Mout = repmat(M, [n_x, n_y, 1]);
    %%
    
    specs_out = copy(specs);
    
    specs_out.AddToHistory("upsampled", {});
    specs_out.AddBinning( 1/sqrt(n_x*n_y) );
    
    specs_out.AddToHistory(functionCallStruct({'n_x','n_y','options'})); 
    %%
   
    displog("movieUpsample: plotting illustrations")
    
    fig_2dmean = plt.getFigureByName("movieUpsample");
    subplot(1,2,1); imshow(mean(M,3), []); title("mean");
    subplot(1,2,2); imshow(mean(Mout,3), []); title("mean upsampled");
    %%
    
    displog("movieUpsample: saving")
    
    rw.h5saveMovie(fullpath_out, Mout, specs_out);
    saveas(fig_2dmean, fullfile(options.diagnosticdir, filename_out + "_2dmean.png"))
    saveas(fig_2dmean, fullfile(options.diagnosticdir, filename_out + "_2dmean.fig"))
end
%%

function options = parseInputs(basepath, varargin)
    
    p = inputParser();
    
    p.addParameter('diagnosticdir', ...
        fullfile(basepath, "\diagnostic\upsample\"), @(s) isstring(s)|ischar(s));
    
    p.addParameter('outdir', basepath, @(s) isstring(s)|ischar(s));
    p.addParameter('postfix_new', "_upsampled", @(s) isstring(s)|ischar(s));
    p.addParameter('skip', true, @(x) (x==true)|(x==false));

    p.parse(varargin{:});
    options = p.Results;
end
%%


