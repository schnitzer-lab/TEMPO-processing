
function filename_out = movieMeanTraceSpectrogram(fullpath, varargin)

    [basepath, basefilename, ext, postfix] = filenameSplit(fullpath, '_');

    options = defaultOptions(basepath);
    if(~isempty(varargin))
        options = getOptions(options, varargin);
    end

    if (~isfolder(options.processingdir)) mkdir(options.processingdir); end
    
    basepath_out = basefilename + postfix+options.postfix_new + ...
        "_tw" + string(options.timewindow) + "fw" + string(options.fw);
%     if(~isempty(options.bgmethod)) basepath_out = basepath_out+string(options.bgmethod); end
    filename_out = fullfile(options.processingdir, basepath_out + ".h5");
    
    if(isfile(filename_out))
        if(options.skip)
            disp("movieMeanTraceSpectrogram: Output file exists. Skipping: "  + filename_out)
            return;
        else
            warning("movieMeanTraceSpectrogram: Output file exists. Deleting first: " + filename_out);
            delete(filename_out);
        end    
    end
    %%

    specs = rw.h5readMovieSpecs(fullpath);
    m =  rw.h5getMeanTrace(fullpath, 'nframes_read', options.nframes_read ); %squeeze(sum(M,[1,2], 'omitnan'));
    %%

    w = round(options.timewindow*specs.getFps());
    dw = round(w*options.overlap);
    nw = options.fw*w/specs.getFps()/2;

    [st,fs,ts] = proc.SpectrogramMultitaper(m, w, 'overlap', dw, 'nw', nw, 'fps', specs.getFps());
    
    st(fs < specs.getFrequencyRange(1) | fs > specs.getFrequencyRange(2), :) = [];
    fs(fs < specs.getFrequencyRange(1) | fs > specs.getFrequencyRange(2)) = [];  
    
    if(~isempty(options.frange))
        st(fs < options.frange(1) | fs > options.frange(2), :) = [];
        fs(fs < options.frange(1) | fs > options.frange(2)) = [];  
    end
    %%
    
%     if(~isempty(options.bgmethod))
%         if(isempty(options.timewindow_bg)) options.timewindow_bg = 3*options.timewindow; end
%             
%         nbg = round(options.timewindow_bg/(options.timewindow*(1-options.overlap)));
%         if strcmp(options.bgmethod, 'cvx')
%             bg = proc.SpectrogramBackgroundsCVX(st, nbg);
%         elseif strcmp(options.bgmethod, '1overf')
%             bg = proc.SpectrogramBackgrounds1fFit(st, nbg);
%         else
%             warning(string(options.bgmethod) + " background method undefined")
%             bg = ones(size(st));
%         end            
%     else 
%         bg = ones(size(st));
%     end
    
    
    %%
       
    fig = plt.getFigureByName("movieMeanTraceSpectrogram");

    options_spectrogram = struct('q', [0.05, 0.999], ...
        'trace', m, 'trace_ts', ((0:(length(m)-1)) + (specs.timeorigin-1))'/specs.getFps(), ...
        'title', [basepath, basefilename + postfix + ...
            " (dt=" +  num2str(options.timewindow) + ...
            "s, df=" + num2str(options.fw) + "Hz)"]);
    if(options.meanspectra)
        options_spectrogram.spectra = mean(st, 2, 'omitnan'); 
        options_spectrogram.spectra_fs = fs;
    end
         
    ts_plot = ts + (specs.timeorigin-1)/specs.getFps(); 
    plt.signalSpectrogram(st, ts_plot, fs, options_spectrogram);   
    %%

    saveas(fig, fullfile(options.processingdir, basepath_out + ".png"));
    saveas(fig, fullfile(options.processingdir, basepath_out + ".fig"));
    %%
    
    specs_out = copy(specs);
    specs_out.AddToHistory(functionCallStruct({'options'})); 
        
    h5save(filename_out, st, '/st');
    h5save(filename_out, fs, '/fs');
    h5save(filename_out, ts, '/ts');
%     if(~isempty(options.bgmethod))  h5save(filename_out, bg, '/bg'); end
        
    rw.h5saveMovieSpecs(filename_out, specs_out); 
end


function options = defaultOptions(basepath)
    
    options.timewindow = 5;
    options.overlap = 0.75;
    options.fw = 0.5;
    options.nframes_read = Inf;
    options.frange = [];
    
%     options.bgmethod = []; % [], 'cvx' or '1overf'
%     options.timewindow_bg = []; % options.timewindow_bg = 3*options.timewindow;
    
    options.meanspectra = true;
    
    options.processingdir = fullfile(basepath, "\processing\meanTraceSpectrogram\");
    options.postfix_new = "_sp";
    options.skip = true;
end