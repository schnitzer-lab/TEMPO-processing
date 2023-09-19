
function movieMeanTraceSpectrogram(fullpath, varargin)

    [basepath, basefilename, ext, postfix] = filenameSplit(fullpath, '_');

    options = defaultOptions(basepath);
    if(~isempty(varargin))
        options = getOptions(options, varargin);
    end

    if (~isfolder(options.processingdir)) mkdir(options.processingdir); end

    filename_out = fullfile(options.processingdir, basefilename + postfix + ".fig");
    if(isfile(filename_out))
        if(options.skip)
            disp("movieMeanTraceSpectrogram: Output file exists. Skipping: "  + filename_out)
            return;
        else
            warning("movieMeanTraceSpectrogram: Output file exists. Overwriting: " + filename_out);
        end    
    end
    %%

%     [M, specs] = rw.h5readMovie(fullpath);
    specs = rw.h5readMovieSpecs(fullpath);
    m =  rw.h5getMeanTrace(fullpath, 'nframes_read', options.nframes_read ); %squeeze(sum(M,[1,2], 'omitnan'));
%     clear('M');
    %%


    w = round(options.timewindow*specs.getFps());
    dw = round(w*options.overlap);
    nw = options.df*w/specs.getFps()/2;

    fig = plt.getFigureByName("movieMeanTraceSpectrogram");

    plt.signalSpectrogram(m, w, dw, nw, 'fps', specs.getFps(), 'f0', options.f0, 'frame0', specs.timeorigin, ...
        'title', "Spectrogram of the mean trace" + ...
        " (dt=" +  num2str(options.timewindow) + "s, df=" + num2str(options.df) + "Hz)");%, 'correct1f', options.correct1f );

    sgtitle({basepath, basefilename + postfix}, ...
        'FontSize', 12, 'interpreter', 'none');

    saveas(fig, fullfile(options.processingdir, basefilename + postfix + ".png"));
    saveas(fig, fullfile(options.processingdir, basefilename + postfix + ".fig"));

end


function options = defaultOptions(basepath)
    
    options.timewindow = 5;
    options.overlap = 0.5;
    options.f0 = 0;
    options.df = 0.5;
    options.nframes_read = Inf;
    %options.correct1f = false;
    
    options.processingdir = fullfile(basepath, "\processing\meanTraceSpectrogram\");
    options.skip = true;
end