function signalSpectrogram(m, w, dw, nw, varargin)

    options = defaultOptions();
    if(~isempty(varargin))
        options = getOptions(options, varargin);
    end


    st = proc.SpectrogramMultitaper(m, w, 'overlap', dw, 'nw',nw, ...
        'correct1f', options.correct1f);
    st = flip(st, 1);

    fs = (0:(size(st, 1)-1))/(size(st, 1)-1)*options.fps/2;
    ts = ((0:(size(st,2)-1))*(w-dw) + (w-dw)/2 + options.frame0 - 1)/options.fps; % timestamps for spectrogram intervals
    ts0 = ( (0:(length(m)-1)) + options.frame0 - 1)/options.fps; % timestamps for individual frames
    
    if(isnan(options.flims(1))) options.flims(1) = min(fs); end
    if(isnan(options.flims(2))) options.flims(2) = max(fs); end
    
    frange_plot = find(fs >= options.flims(1), 1): ...
                  find(fs <= options.flims(2), 1, 'last');
    frange_clim = find(fs >= options.f0 & fs >= options.flims(1), 1):...
                  find(fs <= options.flims(2), 1, 'last');


    subplot(4,4,[2:4,(2:4) + 4, (2:4) + 4*2 ])
    st= flip(st,1);
    imagesc(ts, fs(frange_plot), st(frange_plot, :)); 

    grid on;
    set(gca,'GridColor',[1 1 1]) 
%     set(gca,'xticklabel',[], 'yticklabel', [])
    
    xlim([min(ts0), max(ts)]);
%     ylim(minmax(fs));
    caxis([quantile(st(frange_clim,:), options.q(1), 'all'), ...
           quantile(st(frange_clim,:), options.q(2), 'all')])
    if(~options.correct1f) set(gca,'ColorScale','log'); end
    colormap('jet');
    % axis image
    title(options.title, 'Interpreter', 'none');

    %%

    subplot( 4,4,[(2:4) + 4*3 ])
    plot(ts0, m); xlim([min(ts0), max(ts)]);
    xlabel("s"); ylabel('signal');
    grid on;
    
    xlim([min(ts0), max(ts)]);
    %%
    
    subplot( 4,4,[1, 1+4, 1+4*2])


%     nw0 = nw*length(m)/w;

%     z = pmtm(m, nw0); %out of memory for really long traces (n ~4e5) 
    z = sum(st,2,'omitnan' );

    fs = (0:(length(z)-1))/(length(z)-1)*options.fps/2;
    frange_plot = find(fs >= options.flims(1), 1): ...
                  find(fs <= options.flims(2), 1, 'last');
    frange_clim = find(fs >= options.f0 & fs >= options.flims(1), 1):...
                  find(fs <= options.flims(2), 1, 'last');

    if(~options.correct1f) semilogy(fs(frange_plot), z(frange_plot)); 
    else plot(fs(frange_plot), z(frange_plot)); end

    xlim(minmax(fs(frange_plot))); ylim(minmax(z(frange_clim)').*[1, 2])
    xlabel("Hz"); ylabel('averaged spectrogram');
    set(gca,'xaxisLocation','top');
    set(gca,'yaxisLocation','right');
    set(gca,'XDir','reverse'); camroll(90);
    grid on;
    %%
end

function options = defaultOptions()
    
    options.fps = 1;
    options.frame0 = 1; % # fisplacement of the the first frame for proper time axis
    options.flims = [NaN,NaN]; %frequency limits to plot
    options.f0 = 0; % minimum frequency to take into account for caxis limits
    options.q = [0.5, 1]; %quantiles for caxis limits
    options.title = "Spectrogram";
    options.correct1f = false;
end
