function ConvolutionalBandpassFilter(conv_trans, fps, f0, wp, wr, attn, rppl )
    
    subplot(1,4,1)
    ts_plot = linspace(-length(conv_trans)/2, length(conv_trans)/2, length(conv_trans))/fps;
    plot(ts_plot, conv_trans)
    xlim(minmax(ts_plot))
    ylim(minmax(conv_trans'))
    xlabel('time, s')
    title(['\tau ~', num2str(round(length(conv_trans)/fps/2,1)), 's'])
    grid

    %somewhat different from freqz(H), likely due to different computation
    filter_amp = abs(fftshift(fft(conv_trans)));
    filter_amp = filter_amp(ceil(size(filter_amp,1)/2):end);
    fs = linspace(0, fps/2, size(filter_amp, 1));

    subplot(1,4,2)
    semilogy(fs, filter_amp, 'LineWidth', 1); hold on;
    yline(1/attn, '--'); hold off;
    ylim([1e-1/attn,10^0])
    xlabel('frequency, Hz')
    title(['f_0 =', num2str(f0), 'Hz, ', 'atten =', num2str(1/attn, '%.1e')])
    grid

    subplot(1,4,3)
    semilogy(fs, filter_amp, 'LineWidth', 1); hold on;
    xline(f0-wp, '--'); xline(f0+wp, '--');
    xline(f0-wp-wr, '--'); xline(f0+wp+wr, '--'); hold off;
    xlim([f0-wp-3*wr, f0+wp+3*wr])
    ylim([1e-1/attn,10^0])
    xlabel('frequency, Hz')
    title(['w_p=', num2str(wp), 'Hz, ', 'w_r=', num2str(wr), 'Hz' ])
    grid


    subplot(1,4,4)
    plot(fs, filter_amp, 'LineWidth', 1); hold on;
    yline(1-rppl/2, '--'); yline(1+rppl/2, '--'); hold off;
    xlim([f0-wp-wr, f0+wp+wr])
    ylim([1*(1-rppl),1*(1+rppl)])
    xlabel('frequency, Hz')
    title(['ripple = ', num2str(rppl, '%.1e') ])
    grid
end

