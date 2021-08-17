function signalSpectrogram(m, w, dw, nw, varargin)

    options = defaultOptions();
    if(~isempty(varargin))
        options = getOptions(options, varargin);
    end


    st = proc.SpectrogramMultitaper(m, w, 'overlap', dw, 'nw',nw);
    st = flip(st, 1);

    fs = (0:(size(st, 1)-1))/(size(st, 1)-1)*options.fps/2;
    ts = ((0:(size(st,2)-1))*(w-dw) + (w-dw)/2 + options.frame0 - 1)/options.fps;
    ts0 = ( (0:(length(m)-1)) + options.frame0 - 1)/options.fps;

    frange = find(fs >= options.f0, 1):(size(st, 1));


    subplot(4,4,[2:4,(2:4) + 4, (2:4) + 4*2 ])
    st= flip(st,1);
    imagesc(ts, fs, st); 

    grid on;
    set(gca,'GridColor',[1 1 1]) 
    set(gca,'xticklabel',[], 'yticklabel', [])
    
    xlim([min(ts0), max(ts)]);
%     ylim(minmax(fs));
    caxis([quantile(st(frange,:), .5, 'all'), quantile(st(frange,:), 1, 'all')])
    set(gca,'ColorScale','log'); colormap('jet');
    % axis image
    title(options.title);

    %%

    subplot( 4,4,[(2:4) + 4*3 ])
    plot(ts0, m); xlim(minmax(ts));
    xlabel("s"); ylabel('signal');
    grid on;
    
    xlim([min(ts0), max(ts)]);
    %%
    
    subplot( 4,4,[1, 1+4, 1+4*2])


%     nw0 = nw*length(m)/w;

%     z = pmtm(m, nw0); %out of memory for really long traces (n ~4e5) 
    z = sum(st,2);

    fs = (0:(length(z)-1))/(length(z)-1)*options.fps/2;
    frange = find(fs >= options.f0, 1):(length(z));


    semilogy(fs, z); xlim(minmax(fs)); ylim(minmax(z(frange)').*[1, 2])
    xlabel("Hz"); ylabel('averaged spectrogram');
    set(gca,'xaxisLocation','top');
    set(gca,'yaxisLocation','right');
    set(gca,'XDir','reverse'); camroll(90);
    grid on;
    %%
end

function options = defaultOptions()
    
    options.fps = 1;
    options.f0 = 0;
    options.frame0 = 1;
    options.title = "Spectrogram";
end
