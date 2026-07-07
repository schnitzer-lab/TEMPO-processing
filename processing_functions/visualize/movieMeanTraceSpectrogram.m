
function filename_out = movieMeanTraceSpectrogram(fullpath, varargin)

    [basepath, filename, ext] = fileparts(fullpath);

    options = parseInputs(basepath, varargin{:});

    if (~isfolder(options.processingdir)), mkdir(options.processingdir); end
    
    basepath_out = filename + options.postfix_new + ...
        "_tw" + string(options.timewindow) + "fw" + string(options.fw);
    if(~isempty(options.bgmethod)), basepath_out = basepath_out+string(options.bgmethod); end
    
    filename_out = fullfile(options.processingdir, basepath_out + ".h5");
    filename_out_bg = fullfile(options.processingdir, basepath_out + "bg" + ".h5");
    
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
    m =  rw.h5getMeanTrace(fullpath, 'nframes_read', options.nframes_read, 'mask', false); %squeeze(sum(M,[1,2], 'omitnan'));
    %%

    w = round(options.timewindow*specs.getFps());
    dw = round(w*options.overlap);
    nw = options.fw*w/specs.getFps()/2;

    [st,fs,ts] = proc.SpectrogramMultitaper(m, w, 'overlap', dw, 'nw', nw, 'fps', specs.getFps());
    
    % tot_st = sum(st(:))*mean(diff(fs))*mean(diff(ts));
    % tot_m = sum(m.^2)*(1/ specs.getFps());

    amp_st = mean(sum(st, 1),2)*mean(diff(fs));
    amp_m = mean(m.^2);

    assert(2*(amp_st-amp_m)/(amp_st+amp_m) < 0.08, ...
        "movieMeanTraceSpectrogram: norm difference")
    
    st = st*amp_m/amp_st;
    ts = ts + (specs.timeorigin-1)/specs.getFps();
    %%

    bg = ones(size(st));
    if(~isempty(options.bgmethod))
        %%
        
        if(isempty(options.frange)), options.frange = specs.getFrequencyRange(); end
        st(fs < options.frange(1) | fs > options.frange(2), :) = [];
        fs(fs < options.frange(1) | fs > options.frange(2)) = [];  

        if(isempty(options.timewindow_bg)), options.timewindow_bg = 3*options.timewindow; end

        nbg = round(options.timewindow_bg/(options.timewindow*(1-options.overlap)));
        if strcmp(options.bgmethod, 'cvx')
            bg = proc.SpectrogramBackgroundsCVX(st, nbg);
        elseif strcmp(options.bgmethod, '1overf')
            bg = proc.SpectrogramBackgrounds1fFit(st, nbg);
        elseif strcmp(options.bgmethod, 'quantile')
            bg = quantile(st, 0.05, 2);
        else
            warning(string(options.bgmethod) + " background method undefined")
            bg = ones(size(st));
        end            
    end
    %%
       
    fig = plt.getFigureByName("movieMeanTraceSpectrogram");
    fig.Units = 'inches'; fig.Position(3) = 4*3; fig.Position(4) = 2*(2+options.meantrace);
    
    t_start = options.absorigin*(specs.timeorigin-1)/specs.getFps();
    ts_trace = (0:(length(m)-1))'/specs.getFps() + t_start;
    ts_plot = ts - (ts(1)+t_start)*(1-options.absorigin); 
    
    if(isempty(options.frange)), options.frange = specs.getFrequencyRange(); end
    
    options.frange(1) = max(options.frange(1), specs.getFrequencyRange(1));
    options.frange(2) = min(options.frange(2), specs.getFrequencyRange(2));
    toplotz = @(p) p(fs >= options.frange(1) & fs <= options.frange(2), :) ;
    
    options_spectrogram = struct('q', options.qplot,...
        'xlabel', 'Time (s)', 'ylabel', 'Frequency (Hz)', ...
        'clabel', '', 'title', '');
    if(options.meantrace)
        options_spectrogram.trace = m;
        options_spectrogram.trace_ts = ts_trace;
    end
    if(options.meanspectrum)
        options_spectrogram.spectra = mean(toplotz(st)./toplotz(bg), 2, 'omitnan'); 
        options_spectrogram.spectra_fs = toplotz(fs);
    end 
       
    axes_all = plt.signalSpectrogram(toplotz(st)./toplotz(bg), ...
        ts_plot, toplotz(fs), options_spectrogram);   

    sgtitle({"dt=" +  num2str(options.timewindow) + ...
           "s, df=" + num2str(options.fw) + "Hz: " + ...
           specs.recording_id, filename}, ...
           'interpreter', 'none', 'FontSize', 10,'FontWeight','bold')
    
    
    flim = get(axes_all(1), 'YLim');
    if(~isempty(options.frange))
        set(axes_all(1), 'YLim', [max([flim(1), options.frange(1)]), ...
                                  min([flim(2), options.frange(2)])] )
    end    

    ax_cb = axes_all(1).Colorbar; ax_cb.Label.String = "Power";
    new_ticks = ceil(log10(ax_cb.Limits(1))):1:floor(log10(ax_cb.Limits(2)));
    axes_all(1).Colorbar.Ticks = 10.^(new_ticks);
    if(~isempty(options.bgmethod)), ax_cb.Label.String = ax_cb.Label.String + " (rel)";
    else, axes_all(1).Colorbar.Label.String  = ax_cb.Label.String + " (Hz-1)"; end
    if(~isempty(options.bgmethod)), cl = clim(axes_all(1)); clim(axes_all(1), [1, cl(2)]); end    
    
    if(options.meantrace)
        drawnow();
        p_ax_trace = get(axes_all(2), 'Position');
        p_ax_ax_spectrogram = get(axes_all(1), 'Position');
        set(axes_all(2), 'Position', ...
                [p_ax_ax_spectrogram(1), p_ax_trace(2), ...
                 p_ax_ax_spectrogram(3), p_ax_trace(4)]);
    end
    %%
    tstart_ttl = (specs.timeorigin-1)/specs.getFps();

    if(options.plot_ttl && ~isempty(specs.getTTLTrace()))
        ttl = specs.getTTLTrace(length(m));
        if(options.meantrace)
            hold(axes_all(2), 'on')
            h_ttl = plot(axes_all(2), ts_trace, ttl*2*std(m) + mean(m), ...
                'Color', [0.8500, 0.3250, 0.0980]);
            uistack(h_ttl, 'bottom')
            hold(axes_all(2), 'off')            
        else
            flim = get(axes_all(1), 'YLim');
            plotSignalOnSpectrogram(axes_all(1), ts_trace, logical(ttl ~= 0), ...
                [0.89, 0.97]*max(flim), [1,1,1]*0.9);
        end
    end

    if(~isempty(options.extra_signal))
        sig = options.extra_signal(:);
        sig = sig(1:min([length(ts_trace), length(sig)]));
        if(options.meantrace)
            hold(axes_all(2), 'on')
            h_sig = plot(axes_all(2), ts_trace(1:length(sig))-tstart_ttl, zscore(sig)*std(m) + mean(m) + 3*std(m), ...
                'Color', [0.3, 0.7, 0.1]);
            uistack(h_sig, 'bottom')
            hold(axes_all(2), 'off')
        else
            flim = get(axes_all(1), 'YLim');
            plotSignalOnSpectrogram(axes_all(1), ts_trace(1:length(sig))-tstart_ttl, sig, ...
                [0.85, 0.93]*max(flim), 'white');
        end
    end
    %%
    
    if(options.savepdf), exportgraphics(fig, fullfile(options.processingdir, basepath_out + ".pdf")); end
    saveas(fig, fullfile(options.processingdir, basepath_out + ".png"));
    saveas(fig, fullfile(options.processingdir, basepath_out + ".fig"));
    %%
    
    specs_out = copy(specs);
    specs_out.AddToHistory(functionCallStruct({'options'})); 
    specs_out.AddBinningTime(specs.getFps()*unique(round(diff(ts), 2)));    
    specs_out.AddBinning(Inf);
    
    h5save(filename_out, st, '/st');
    h5save(filename_out, fs, '/fs');
    h5save(filename_out, ts, '/ts');
    rw.h5saveMovieSpecs(filename_out, specs_out);
    if(~isempty(options.bgmethod)), h5save(filename_out, bg, '/bg'); end

    % unfortunateley: h5append (line 70) h5write(filename, dataset_name, movie, [1,1,1], movieSize); % movie size needs to have 3 elements RC
    % st_out = reshape(transpose(st), [1, 1, size(st,2), size(st,1)]);
    % specs_out.extra_specs('fs') = fs;
    % rw.h5saveMovie(filename_out, st_out, specs_out);
    % if(~isempty(options.bgmethod))  
        % bg_out = reshape(transpose(bg), [1, 1, size(st,2), size(st,1)]);
        % rw.h5saveMovie(filename_out_bg, bg_out, specs_out);
    % end
end


function plotSignalOnSpectrogram(axis, ts, sig, f_lims, color)
    
    hold(axis, 'on')
    if(islogical(sig))
        f_mid = (f_lims(1) + f_lims(2)) / 2;
        plot(axis, ts(sig), repmat(f_mid, sum(sig), 1), ...
            '|', 'Color', 'black', 'MarkerFaceColor', 'black', 'MarkerSize', 6, 'LineStyle', 'none');
        plot(axis, ts(sig), repmat(f_mid, sum(sig), 1), ...
            '|', 'Color', color, 'MarkerFaceColor', color, 'MarkerSize', 4, 'LineStyle', 'none');
    else
        sig_norm = f_lims(1) + (sig - min(sig, [], 'omitnan')) ./ ...
            (max(sig, [], 'omitnan') - min(sig, [], 'omitnan')) * (f_lims(2) - f_lims(1));
        plot(axis, ts, sig_norm, 'Color', 'black', 'LineWidth', 3);
        plot(axis, ts, sig_norm, 'Color', color, 'LineWidth', 2);
    end
    hold(axis, 'off')
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

    p.addParameter('bgmethod',      [], @(x) isempty(x) || ischar(x) || isstring(x));
    p.addParameter('timewindow_bg', [], @(x) isempty(x) || isnumpos(x));

    p.addParameter('absorigin',     true, islogscal);
    p.addParameter('meantrace',     true, islogscal);
    p.addParameter('meanspectrum',  true, islogscal);
    p.addParameter('plot_ttl',      true, islogscal);
    p.addParameter('extra_signal',  [],   @(x) isempty(x) || isnumeric(x) || islogical(x));

    p.addParameter('qplot',         [0.05, 0.999],   @(x) (isnumeric(x) && numel(x) == 2));

    p.addParameter('processingdir', fullfile(basepath, 'processing', 'meanTraceSpectrogram'), ...
        @(s) ischar(s) || isstring(s));
    p.addParameter('savepdf',       false,  islogscal);

    p.addParameter('postfix_new',  "_sp", @(s) ischar(s) || isstring(s));
    p.addParameter('skip',         true,  islogscal);

    p.parse(varargin{:});
    options = p.Results;
end