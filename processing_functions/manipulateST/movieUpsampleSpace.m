function fullpath_out = movieUpsampleSpace(fullpath_movie, nx, ny, varargin)
    
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
    
    displog("movieUpsampleSpace: reading movie")
    [M, specs] = rw.h5readMovie(fullpath_movie);
    %%

    Mup = repmat(M, [nx, ny, 1]);
    %%

    specs_out = copy(specs);

    specs_out.AddBinning( 1/sqrt(nx*ny) );

    specs_out.AddToHistory(functionCallStruct({'nx','ny','options'}));
    %%
   
    displog("movieUpsampleSpace: plotting illustrations")
    
    fig_2dmean = plt.getFigureByName("movieUpsample");
    subplot(1,2,1); imshow(mean(M,3), []); title("mean");
    subplot(1,2,2); imshow(mean(Mup,3), []); title("mean upsampled");
    %%
    
    displog("movieUpsampleSpace: saving")
    
    rw.h5saveMovie(fullpath_out, Mup, specs_out);
    saveas(fig_2dmean, fullfile(options.diagnosticdir, filename_out + "_2dmean.png"))
    saveas(fig_2dmean, fullfile(options.diagnosticdir, filename_out + "_2dmean.fig"))
    %%

    m = squeeze(mean(M, [1,2], 'omitnan'));
    m_up = squeeze(mean(Mup(1:size(M,1), 1:size(M,2), :), [1,2], 'omitnan'));

    fig_traces = plt.getFigureByName("movieUpsampleSpace - traces comparison");
    plt.tracesComparison([m, m_up], 'fps', specs_out.getFps(),...
        'labels', ["original", "upsampled"])

    saveas(fig_traces, fullfile(options.diagnosticdir, filename_out + '_traces.png') )
    saveas(fig_traces, fullfile(options.diagnosticdir, filename_out + '_traces.fig') )
end
%%

function options = parseInputs(basepath, varargin)
    
    p = inputParser();
    
    p.addParameter('diagnosticdir', ...
        fullfile(basepath, "\diagnostic\upsampleSpace\"), @(s) isstring(s)|ischar(s));
    
    p.addParameter('outdir', basepath, @(s) isstring(s)|ischar(s));
    p.addParameter('postfix_new', "_upSpace", @(s) isstring(s)|ischar(s));
    p.addParameter('skip', true, @(x) (x==true)|(x==false));

    p.parse(varargin{:});
    options = p.Results;
end
%%


