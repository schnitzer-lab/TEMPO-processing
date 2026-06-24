function axes_all = signalSpectrogram(st, ts, fs, varargin)

    options = defaultOptions();
    if(~isempty(varargin))
        options = getOptions(options, varargin);
    end   

    %%  
    
    if(isempty(options.trace_ts)) 
        options.trace_ts = interp1(ts, linspace(0,1,length(ts)), linspace(0,1,length(options.trace))); 
    end
    if(isempty(options.spectra_fs)) 
        options.spectra_fs = interp1(fs, linspace(0,1,length(fs)), linspace(0,1,length(options.spectra_fs))); 
    end              
    %%

    if(isnan(options.flims_plot(1))), options.flims_plot(1) = min(fs); end
    if(isnan(options.flims_plot(2))), options.flims_plot(2) = max(fs); end
    %%
    
    if(options.fillnan)
        for i_f = 1:size(st,1)
            st(i_f,:) = interp1(ts(~isnan(st(i_f,:))), st(i_f,~isnan(st(i_f,:))), ts);
        end
    end
    %%
    
    ax_spectrogram = options.ax_spectrogram; ax_trace = []; ax_spectra = [];
    
    nv = 4; nh = 6;
    sp_num = reshape((1:nv*nh), nh, nv)';
    if(isempty(options.trace) && isempty(options.spectra) && isempty(ax_spectrogram))
        ax_spectrogram = subplot(1,1,1);
%         plt.prepAxis(true);
    elseif(~isempty(options.trace) && isempty(options.spectra) && isempty(ax_trace))
        ax_spectrogram = subplot(nv, nh, reshape(sp_num(1:(end-1), 1:end), 1, []) ); 
%         plt.prepAxis(false);
        ax_trace = subplot(nv, nh, reshape(sp_num(end, 1:end), 1, []) );   
%         plt.prepAxis(false);
    elseif(isempty(options.trace) && ~isempty(options.spectra) && isempty(ax_spectra))
        ax_spectrogram = subplot(nv, nh, reshape(sp_num(:, 2:end), 1, []) ); 
%         plt.prepAxis(true);
        ax_spectra = subplot(nv, nh, reshape(sp_num(:, 1), 1, []) );    
%         plt.prepAxis(false);      
    elseif(~isempty(options.trace) && ~isempty(options.spectra) && isempty(ax_trace) && isempty(ax_spectra))
        ax_spectrogram = subplot(nv, nh, reshape(sp_num(1:(end-1), 2:end), 1, []) );
        ax_trace = subplot(nv, nh, reshape(sp_num(end, 2:end), 1, []));  
        ax_spectra = subplot(nv, nh, reshape(sp_num(1:(end-1), 1), 1, []));  
    end

    axes_all = [ax_spectrogram, ax_trace, ax_spectra];
    %%
    
    im = imagesc(ax_spectrogram, ts, fs, st); 
    set(im, 'AlphaData', ~isnan(st));
    
    set(ax_spectrogram,'GridColor',[1 1 1]) 
    set(ax_spectrogram,'YDir','normal')
    
    xlim([min(ts), max(ts)]);
    ylim(options.flims_plot);
        
    data_distr = st(fs >= options.flims_plot(1) & fs <= options.flims_plot(2),:);
    data_distr = data_distr(:);
    set(ax_spectrogram, 'CLim', ...
        [quantile(data_distr, options.q(1))+...
            min(data_distr(data_distr>0)*strcmp(options.colorscale,"Log") ), ...
         quantile(data_distr, options.q(2))])
    
    set(ax_spectrogram,'ColorScale', options.colorscale)
    colormap(ax_spectrogram, 'turbo'); 
    cb = colorbar(ax_spectrogram); cb.Label.String = options.clabel; 
    cb.Label.Rotation = -90; cb.Label.Position(1) = cb.Label.Position(1)*1.4;
    
    xlabel(ax_spectrogram, options.xlabel); ylabel(ax_spectrogram, options.ylabel);
    title(ax_spectrogram, options.title);
 
    %%
    
    if(~isempty(options.spectra))
        
%         set(ax_spectrogram,'yticklabel',[])
        set(ax_spectrogram,'ylabel',[])
        
        plot(ax_spectra, options.spectra_fs, options.spectra); 
        xlim(ax_spectra, options.flims_plot);
        
        xlabel(ax_spectra, options.ylabel); ylabel(ax_spectra, options.clabel);
        grid(ax_spectra,  'off');
        
%         linkaxes([ax_spectrogram ax_spectra],'y') % How to link y1 to x2?
        
        set(ax_spectra,'xaxisLocation','top');
        set(ax_spectra,'yaxisLocation','left');
        camroll(ax_spectra, 90);
        set(ax_spectra, 'YScale', options.colorscale)
        
    end
   %%
        
    if(~isempty(options.trace))
    
        set(ax_spectrogram,'xticklabel',[])
        set(ax_spectrogram,'xlabel',[])
        
        plot(ax_trace, options.trace_ts, options.trace); 
        xlabel(ax_trace, options.xlabel);
        % grid on;
        
        xlim(ax_trace, [min(ts), max(ts)]);
        
        drawnow();
        p_ax_trace = get(ax_trace, 'Position');
        p_ax_ax_spectrogram = get(ax_spectrogram, 'Position');
        set(ax_trace, 'Position', ...
            [p_ax_ax_spectrogram(1), p_ax_trace(2), ...
             p_ax_ax_spectrogram(3), p_ax_trace(4)]);
        linkaxes([ax_spectrogram ax_trace],'x')

    end
    %%
    
    
end

function options = defaultOptions()
   
    options.flims_plot = [NaN,NaN]; %frequency limits to plot
    
    options.fillnan = false;
    
    options.q = [0.1, 1]; %quantiles for caxis limits
    options.colorscale = "Log";
    
    options.title = "Spectrogram";
    options.xlabel = "Time";
    options.ylabel = "Frequency";
    options.clabel = "Power";

    options.trace = [];
    options.trace_ts = [];
    options.spectra = [];
    options.spectra_fs = [];

    options.ax_spectrogram = [];
end


