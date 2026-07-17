
function unmixingFilterComparison(W0, W, specs)
    %%
    fps = specs.getFps();
    frange = specs.getFrequencyRange();
    wn = size(W, 3);

    color_w0 = [0, 0.4470, 0.7410];
    color_w = [0.8500, 0.3250, 0.0980];
    color_diff = [0.4940, 0.1840, 0.5560];
    %%

    subplot(3,1,1)

    relmap = sum((W0-W).^2, 3) ./ sum(W.^2, 3);

    im_show = plt.saturate(relmap, 0.01);
    im1 = imshow(im_show, []);
    if(~isempty(specs.getMask()))
        set(im1, 'AlphaData', logical(specs.getMask()))
    end
    colormap(gca, parula);
    caxis([0, max(im_show(:))]);

    % title('Relative filter change: |W0-W|^2 / |W|^2')

    cb = colorbar();
    cb.Label.String = "Relative power change";
    cb.Label.Rotation = -90;
    cb.Label.Position = cb.Label.Position + [1,0,0];
    cb.Label.FontSize = 11;
    %%

    Wdiff = W0-W;
    Wdiff_flat = reshape(Wdiff, [], wn);
    sampled_points = randsample(1:size(Wdiff_flat,1), min(size(Wdiff_flat,1), 1000));
    Wsampled_diff = Wdiff_flat(sampled_points, :);

    w0 = squeeze(mean(W0, [1,2], 'omitnan'));
    w  = squeeze(mean(W,  [1,2], 'omitnan'));
    wdiff = w0-w;

    ts = ((1:wn)-(wn+1)/2)/fps;

    subplot(3,1,2)

    plot(ts, transpose(Wsampled_diff), ...
        'color', [color_diff, 10/length(sampled_points)]); hold on;

    plot(ts, w0, 'LineWidth', 1.5, 'Color', color_w0);
    plot(ts, w, 'LineWidth', 1.5, 'Color', color_w);
    plot(ts, wdiff, 'LineWidth', 1.5, 'Color', color_diff);

    legend([repelem("", length(sampled_points)), "W0", "W", "W0-W"], 'FontSize', 12);

    hold off; grid on; xlim([min(ts), max(ts)]);
    ylim(1.5*[min([w0; w; wdiff], [], 'omitnan'), max([w0; w; wdiff], [], 'omitnan')]);
    xlabel('Time, s'); ylabel('Filter amplitude');
    %%

    fs = linspace(0, fps, wn);
    ZWdiff = transpose(fft(transpose(Wsampled_diff)));
    zw0 = fft(w0); zw = fft(w); zwdiff = fft(wdiff);

    ZWdiff(:, fs <= frange(1)) = NaN;
    zw0(fs <= frange(1)) = NaN;
    zw(fs <= frange(1)) = NaN;
    zwdiff(fs <= frange(1)) = NaN;

    subplot(3,1,3)

    plot(fs, abs(transpose(ZWdiff)), ...
        'color', [color_diff, 10/length(sampled_points)]); hold on;

    plot(fs, abs(zw0), 'LineWidth', 1.5, 'Color', color_w0);
    plot(fs, abs(zw), 'LineWidth', 1.5, 'Color', color_w);
    plot(fs, abs(zwdiff), 'LineWidth', 1.5, 'Color', color_diff);

    legend([repelem("", length(sampled_points)), "W0", "W", "W0-W"], 'FontSize', 12);

    hold off; grid on; xlim([0, fps/2]);
    ylim([0, 2*max([abs(zw0); abs(zw); abs(zwdiff)], [], 'omitnan')]);
    xlabel('Frequency, Hz'); ylabel('Spectral amplitude');
end
%%
