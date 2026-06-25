
function unmixingFilter(Wall, fps, options)
    %%

    ts = ((1:size(Wall,2))-(size(Wall,2)+1)/2)/fps;
    fs = linspace(0, fps, size(Wall,2));
    %%

    w = squeeze(mean(Wall, 1, 'omitnan'))';

    sampled_points = randsample(1:size(Wall,1), min(size(Wall,1), 1000));
    
    Wsampled = Wall(sampled_points, :);
    ZW = transpose(fft(transpose(Wsampled)));
    zw = fft(w);
 
    subplot(3,1,1)
    plot(ts, transpose(Wsampled), ...
        'color', [0.5,0.5,0.9,10/length(sampled_points)]); hold on;
    plot( ts, w, 'LineWidth', 1.5, 'Color', 'blue'); 
    
    legend([repelem("", length(sampled_points)), "time representation"]); 
    
    hold off; grid on;
    xlim([min(ts), max(ts)]); ylim([floor(min(w)/0.25), ceil(max(w)/0.25)]*0.25)
    xlabel('Time, s'); 
    %%

    subplot(3,1,2)

    ZW(:, fs <= options.frange(1)) = NaN;
    zw(fs <= options.frange(1)) = NaN;
    [~,ind_f0] = min(abs(fs-options.fref));

    semilogy(fs, abs(ZW), 'color', ...
        [0.5,0.5,0.9,10/length(sampled_points)]); hold on;
    semilogy(fs, abs(zw), '.-', 'LineWidth', 1.5, 'Color', 'blue');     
    legend([repelem("", length(sampled_points)), "spectral amplitude"], ...
        'Location', 'southeast');

    if(options.max_amp_rel < inf)
        a = max(abs(zw(ind_f0)), median(abs(zw)));
        line([0, options.flim_max], ...
             [1, 1]*options.max_amp_rel*a, ...
            'LineStyle', '--', 'Color', 'black', 'LineWidth', 1);
        scatter(options.fref, abs(zw(ind_f0)), 'o', 'red')

        legend([repelem("", length(sampled_points)), "spectral amplitude", ...
            "limit ("+num2str(options.max_amp_rel)+"*ref)", "reference"]);
    end

    hold off; grid on;
    xlim([0, fps/2]); % ylim([0.9, 1.3].*[min(abs(zw')), max(abs(zw'))]);
    xlabel('Frequency, Hz');

    %%

    subplot(3,1,3)
    
    idf = zeros(size(w)); idf(floor((length(w)+1)/2)) = 1;
    ids = fft(idf);

    pd = -mod(unwrap(angle(zw./abs(zw)./ids))+pi/2, pi)+pi/2;
    PD = -mod(unwrap(angle(ZW./abs(ZW)./transpose(ids)))+pi/2, pi)+pi/2;

    plot(fs, transpose(PD), 'color', [0.5,0.5,0.9,0.01]); hold on
    plot(fs, pd, '.-', 'LineWidth', 1.5, 'color', 'blue');
    
    plot(fs,  options.max_delay*2*pi*fs, '--', 'color', 'Black', 'LineWidth', 1)
    plot(fs, -options.max_delay*2*pi*fs, '--', 'color', 'Black', 'LineWidth', 1)
    
    legend([repelem("", length(sampled_points)), "phase delay", ...
        "max delay ("+num2str(round(options.max_delay*1000))+"ms)"]); 
    
    hold off; grid on;    
    xlim([0, fps/2]); ylim([-1,1]*pi/2); 
    xlabel('Frequency, Hz'); ylabel('Phase, rad')
end
%%

