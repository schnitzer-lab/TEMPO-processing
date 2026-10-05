function ConvolutionalMultibandFilter(conv_trans, fps, f0s, wps, wr, attn, rppl )
    %%
    nbands = numel(f0s);
    if(isscalar(wr)), wr = repmat(wr, 1, nbands); end
    if(isscalar(attn)), attn = repmat(attn, 1, nbands); end
    if(isscalar(rppl)), rppl = repmat(rppl, 1, nbands); end

    subplot(1,4,1)
    ts_plot = linspace(-length(conv_trans)/2, length(conv_trans)/2, length(conv_trans))/fps;
    plot(ts_plot, conv_trans)
    xlim([min(ts_plot), max(ts_plot)])
    ylim([min(conv_trans'), max(conv_trans')] )
    xlabel('time, s')
    title(['\tau ~', num2str(length(conv_trans)/fps/2, '%.2f'), 's'])
    grid

    %somewhat different from freqz(H), likely due to different computation
    filter_amp = abs(fftshift(fft(conv_trans)));
    filter_amp = filter_amp(ceil(size(filter_amp,1)/2):end);
    fs = linspace(0, fps/2, size(filter_amp, 1));

    attn_max = max(attn);

    subplot(1,4,2)
    semilogy(fs, filter_amp, 'LineWidth', 1); hold on;
    yline(1/attn_max, '--'); hold off;
    ylim([1e-1/attn_max,10^0])
    xlabel('frequency, Hz')
    title(["f_0 ="+mat2str(f0s)+"Hz,", "atten ="+num2str(1/attn_max, '%.1e')])
    grid

    subplot(1,4,3)
    semilogy(fs, filter_amp, 'LineWidth', 1); hold on;
    for i = 1:nbands
        xline(f0s(i)-wps(i), '--'); xline(f0s(i)+wps(i), '--');
        xline(f0s(i)-wps(i)-wr(i), '--'); xline(f0s(i)+wps(i)+wr(i), '--');
    end
    hold off;
    xlim([min(f0s-wps-3*wr), max(f0s+wps+3*wr)])
    ylim([1e-1/attn_max,10^0])
    xlabel('frequency, Hz')
    title(["w_p="+mat2str(wps)+"Hz, ", "w_r="+mat2str(wr)+"Hz" ])
    grid


    subplot(1,4,4)
    plot(fs, filter_amp, 'LineWidth', 1); hold on;
    rppl_max = max(rppl);
    yline(1-rppl_max/2, '--'); yline(1+rppl_max/2, '--'); hold off;
    xlim([min(f0s-wps-wr), max(f0s+wps+wr)])
    ylim([1*(1-rppl_max),1*(1+rppl_max)])
    xlabel('frequency, Hz')
    title(['max ripple = ', num2str(rppl_max, '%.1e') ])
    grid
end
