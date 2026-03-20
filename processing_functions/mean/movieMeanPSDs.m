function fullpaths_out = movieMeanPSDs(fullpaths, varargin)

    [basepath, filename, ext] = fileparts(fullpaths(1));

    options = defaultOptions(basepath);
    if(~isempty(varargin))
        options = getOptions(options, varargin);
    end

    if (~isfolder(options.processingdir)) mkdir(options.processingdir); end
    
    fullpaths_out = strings(size(fullpaths));
    for i_f = 1:length(fullpaths)
        [~, name, ~] = fileparts(fullpaths(i_f));
        fullpaths_out(i_f) = fullfile(options.processingdir, name + "_meanPSD.h5");
    end
    
    if(all(isfile(fullpaths_out)))
        if(options.skip)
            displog("movieMeanPSDs: Output file exists. Skipping: "  + fullpaths_out(1))
            return;
        else
            warning("movieMeanPSDs: Output file exists. Deleting: "  + fullpaths_out(1));
            for i_f = 1:length(fullpaths_out)
                delete(fullpaths_out(i_f));
            end
        end    
    end
    %%

    psds = [];
    labels = [];
    for i_f = 1:length(fullpaths)
        [M,~] = rw.h5readMovie(fullpaths(i_f));
        M = reshape(M, [prod(size(M,[1,2])), size(M,3)]);
        M(all(isnan(M),2),:) = [];
        M(isnan(M)) = 0;
        psd = mean(pwelch(M', 512),2);

        % if(i_f > 1)
        %     if(length(x) < size(psds,1))
        %         psds = psds(1:length(x),:);
        %     else
        %         x = x(1:size(psds,1));
        %     end
        % end
        
        psds = [psds,  psd];

        [~, name, ~] = fileparts(fullpaths(i_f));
        labels = [labels, string(name)];
    end

    specs = rw.h5readMovieSpecs(fullpaths(1));
    %%

    fs = (0:(size(psds,1)-1))./(size(psds,1)-1)*specs.getFps()/2;
    psds(fs < specs.getFrequencyRange(1) | fs > specs.getFrequencyRange(2),:) = NaN;
    psds(end,:) = NaN;

    fig = plt.getFigureByName("Mean PSDs");
    fig.Position(3) = 900;
    semilogy(fs,psds, 'LineWidth', 1);
    legend(labels, 'Interpreter', 'None')

    title({basepath, "Spatially-averaged single-pixel PSDs"}, 'Interpreter', 'none');
    %%
    
    for i_f = 1:length(fullpaths)
        [~, name, ~] = fileparts(fullpaths(i_f));
        fullpath_out = fullfile(options.processingdir, name + "_meanPSD.h5");
        if(isfile(fullpath_out)) delete(fullpath_out); end
        
        specs_out = rw.h5readMovieSpecs(fullpaths(i_f));
        specs_out.AddToHistory(functionCallStruct({'fullpaths', 'options'}));
        rw.h5saveMovie(fullpath_out, ...
            reshape(psds(:,i_f), [1,1,length(psds(:,i_f))]), specs_out);
    end
    
    saveas(fig, fullfile(options.processingdir, filename + ".png"));
    saveas(fig, fullfile(options.processingdir, filename + ".fig"));

end


function options = defaultOptions(basepath)
    
    options.fw = 0.2;
    options.nframes_read = Inf;
    options.skip = true;
    
    options.space = false;
    
    options.processingdir = fullfile(basepath, 'processing', 'meanPSDs');
end