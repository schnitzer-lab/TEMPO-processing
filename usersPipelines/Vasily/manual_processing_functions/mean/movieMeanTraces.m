function fullpaths_out = movieMeanTraces(fullpaths, varargin)

    [basepath, filename, ext] = fileparts(fullpaths(1));

    options = defaultOptions(basepath);
    if(~isempty(varargin))
        options = getOptions(options, varargin);
    end

    if (~isfolder(options.processingdir)) mkdir(options.processingdir); end
    
    fullpaths_out = strings(size(fullpaths));
    for i_f = 1:length(fullpaths)
        [~, name, ~] = fileparts(fullpaths(i_f));
        fullpaths_out(i_f) = fullfile(options.processingdir, name + "_mean.h5");
    end
    
    if(all(isfile(fullpaths_out)))
        if(options.skip)
            disp("movieMeanTraces: Output file exists. Skipping: "  + fullpaths_out(1))
            return;
        else
            warning("movieMeanTraces: Output file exists. Deleting: "  + fullpaths_out(1));
            for i_f = 1:length(fullpaths_out)
                delete(fullpaths_out(i_f));
            end
        end    
    end
    %%

    xs = [];
    labels = [];
    for i_f = 1:length(fullpaths)
        x = rw.h5getMeanTrace(fullpaths(i_f), 'nframes_read', options.nframes_read );
        
        if(i_f > 1)
            if(length(x) < size(xs,1))
                xs = xs(1:length(x),:);
            else
                x = x(1:size(xs,1));
            end
        end
        
        xs = [xs,  x];

        [~, name, ~] = fileparts(fullpaths(i_f));
        labels = [labels, string(name)];
    end

    specs = rw.h5readMovieSpecs(fullpaths(1));
    %%

    fig = plt.getFigureByName("Mean traces");
    plt.tracesComparison(xs, 'labels', labels, 'fps', specs.getFps(), ...
        'fw', options.fw,'f0', options.f0, 't0', (specs.timeorigin-1)/specs.getFps(),...
        'spacebysd', 3*options.space);
    sgtitle({basepath, "Spatially-averaged traces"}, 'Interpreter', 'none');
    %%
    
    for i_f = 1:length(fullpaths)
        [~, name, ~] = fileparts(fullpaths(i_f));
        fullpath_out = fullfile(options.processingdir, name + "_mean.h5");
        if(isfile(fullpath_out)) delete(fullpath_out); end
        
        specs_out = rw.h5readMovieSpecs(fullpaths(i_f));
        specs_out.AddToHistory(functionCallStruct({'fullpaths', 'options'}));
        rw.h5saveMovie(fullpath_out, ...
            reshape(xs(:,i_f), [1,1,length(xs(:,i_f))]), specs_out);
    end
    
    saveas(fig, fullfile(options.processingdir, filename + ".png"));
    saveas(fig, fullfile(options.processingdir, filename + ".fig"));

end


function options = defaultOptions(basepath)
    
    options.f0 = 0.5;
    options.fw = 0.2;
    options.nframes_read = Inf;
    options.skip = true;
    
    options.space = false;
    
    options.processingdir = basepath + "\processing\meanTraces\";
end