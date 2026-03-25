
function filename_out = movieMeanTraceSpectrogram(fullpath, varargin)

    [basepath, filename, ext] = fileparts(fullpath);

    options = parseInputs(basepath, varargin{:});

    if (~isfolder(options.processingdir)), mkdir(options.processingdir); end
    
    basepath_out = filename + options.postfix_new + ...
        "_tw" + string(options.timewindow) + "fw" + string(options.fw);
%     if(~isempty(options.bgmethod)) basepath_out = basepath_out+string(options.bgmethod); end
    filename_out = fullfile(options.processingdir, basepath_out + ".h5");
    
    if(isfile(filename_out))
        if(options.skip)
            displog("Output file exists. Skipping: "  + filename_out)
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
    
    ts_trace = ((0:(length(m)-1)) + (specs.timeorigin-1))'/specs.getFps();
    options_spectrogram = struct('q', [0.05, 0.999], ...
        'title', [basepath, filename + ...
            " (dt=" +  num2str(options.timewindow) + ...
            "s, df=" + num2str(options.fw) + "Hz)"]);
    if(options.meantrace)
        options_spectrogram.trace = m;
        options_spectrogram.trace_ts = ts_trace;
    end
    if(options.meanspectrum)
        options_spectrogram.spectra = mean(st, 2, 'omitnan'); 
        options_spectrogram.spectra_fs = fs;
    end
         
    ts_plot = ts + (specs.timeorigin-1)/specs.getFps(); 
    axes_all = plt.signalSpectrogram(st, ts_plot, fs, options_spectrogram);   
    %%
    if(options.meantrace && ~isempty(specs.getTTLTrace()))
        axes(axes_all(2))
        hold on
        h_ttl = plot(ts_trace, specs.getTTLTrace(length(m))*2*std(m) + mean(m), ...
            'Color', [0.8500, 0.3250, 0.0980]);
        uistack(h_ttl,'bottom')
        hold off
    end
    if(options.meantrace && ~isempty(options.extra_signal))
        axes(axes_all(2))
        hold on
        sig = options.extra_signal(:);
        sig = sig(1:min([length(ts_trace), length(sig)]));
        plot(ts_trace(1:length(sig)), zscore(sig)*std(m) + mean(m) + 3*std(m), ...
            'Color', [0.3, 0.5, 0.1]);
        hold off
    end
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


function options = parseInputs(basepath, varargin)

    p = inputParser();
    isnumpos  = @(x) isnumeric(x) && isscalar(x) && x > 0;
    islogscal = @(x) islogical(x) && isscalar(x);

    p.addParameter('timewindow',   5,    isnumpos);
    p.addParameter('overlap',      0.75, @(x) isnumeric(x) && isscalar(x) && x >= 0 && x < 1);
    p.addParameter('fw',           0.5,  isnumpos);
    p.addParameter('nframes_read', Inf,  isnumpos);
    p.addParameter('frange',       [],   @(x) isempty(x) || (isnumeric(x) && numel(x) == 2));

%     p.addParameter('bgmethod',      [], @(x) isempty(x) || ischar(x) || isstring(x));
%     p.addParameter('timewindow_bg', [], @(x) isempty(x) || isnumpos(x));

    p.addParameter('meantrace',     true, islogscal);
    p.addParameter('meanspectrum',  true, islogscal);
    p.addParameter('extra_signal',  [],   @(x) isempty(x) || isnumeric(x));

    p.addParameter('processingdir', fullfile(basepath, 'processing', 'meanTraceSpectrogram'), ...
        @(s) ischar(s) || isstring(s));
    p.addParameter('postfix_new',  "_sp", @(s) ischar(s) || isstring(s));
    p.addParameter('skip',         true,  islogscal);

    p.parse(varargin{:});
    options = p.Results;
end