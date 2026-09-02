function fullpath_out = movieUpsample(fullpath_movie, nt, ns, varargin)
    
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

    if (nt ~= 1)
        Mup = interpft(M, size(M,3)*nt, 3);
    else
        Mup = M;
    end

    Mup = repmat(Mup, [ns, ns, 1]);
    %%

    specs_out = copy(specs);

    specs_out.AddToHistory("upsampled", {});
    specs_out.AddBinning( 1/ns );
    specs_out.AddBinningTime( 1/nt );

    specs_out.AddToHistory(functionCallStruct({'nt','ns','options'}));
    %%
   
    displog("movieUpsample: plotting illustrations")
    
    fig_2dmean = plt.getFigureByName("movieUpsample");
    subplot(1,2,1); imshow(mean(M,3), []); title("mean");
    subplot(1,2,2); imshow(mean(Mup,3), []); title("mean upsampled");
    %%
    
    displog("movieUpsample: saving")
    
    rw.h5saveMovie(fullpath_out, Mup, specs_out);
    saveas(fig_2dmean, fullfile(options.diagnosticdir, filename_out + "_2dmean.png"))
    saveas(fig_2dmean, fullfile(options.diagnosticdir, filename_out + "_2dmean.fig"))
    %%

    m = squeeze(mean(M, [1,2], 'omitnan'));
    m_up = squeeze(mean(Mup(1:size(M,1), 1:size(M,2), :), [1,2], 'omitnan'));
    m_rep = repelem(m, nt);

    fig_traces = plt.getFigureByName("Upsampling - traces comparison");
    plt.tracesComparison([m_rep(1:length(m_up)), m_up], 'fps', specs_out.getFps(),...
        'labels', ["original", "upsampled"])

    saveas(fig_traces, fullfile(options.diagnosticdir, filename_out + '_traces.png') )
    saveas(fig_traces, fullfile(options.diagnosticdir, filename_out + '_traces.fig') )
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


