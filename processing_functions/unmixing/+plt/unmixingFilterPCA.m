
function unmixingFilterPCA(W, specs)
%%
    saturate = 0.01;

%%

    w = squeeze(mean(W, [1,2], 'omitnan'));
    frange = specs.getFrequencyRange();

    Win = W-repmat(reshape(w, [1,1,length(w)]), [size(W,[1,2]), 1]);
    Win(isnan(Win)) = 0;
    
    [coeff0,score0,latent] = pca(reshape(Win, [prod(size(Win, [1,2])), size(Win,3)])');
        
%     (Win - reshape(coeff*score', size(Win))) == 0
    
    score = score0 .* sqrt(mean(coeff0.^2,1));
    coeff = coeff0 ./ sqrt(mean(coeff0.^2,1));

%     score = score0 ./ sqrt(sum(score0.^2, 1)).^2;
%     coeff = coeff0 .* sqrt(sum(score0.^2, 1));

    coef2d = reshape(coeff, [size(Win, [1,2]), size(coeff, 2)]);
%     coef2d(repmat(nanmask, [1,1, size(coef2d, 3)])) = NaN;
%%

    ax1 = subplot(4,3,1);

    im_show = plt.saturate(sqrt(sum(Win.^2,3)), saturate);
    im1 = imshow(im_show, []);
%     set(im1, 'AlphaData', logical(specs.getMask()))
    colormap(ax1, plt.redblue);  
    caxis([-1,1]*max(abs(im_show(:))));
    
    ht = title(["filter:"]);
    set(ht, 'position', [-50,50,1])
    
    cb = colorbar();
    cb.Label.String = "Total filter amplitude";
    cb.Label.Rotation = -90;
    cb.Label.Position = cb.Label.Position + [1,0,0];
    cb.Label.FontSize = 11;

    ax = subplot(4,3,2);
    ts = (0:(length(w) - 1))/specs.getFps();
    ts = ts - mean(ts)-1/specs.getFps()/2;
    plot(ts, w, 'LineWidth', 1.5); %xlim(minmax(ts))
    xlim( [-1,1]*max(abs(ts)) ); 
    ylabel("Filter amplitude", 'FontSize',11); 
    grid on;
    % title("Time-domain filter")
    grid OFF;
    % ax.YGrid = 'off';
    
    subplot(4,3,3)
    zw = abs(fft(w));
    fs = linspace(0, specs.getFps(), length(zw)); 
    zw(fs < frange(1) | fs > frange(2)) = NaN;
    semilogy(fs, zw, 'LineWidth', 1.5); xlim(minmax(fs)); 
    xlim([0, specs.getFps()/2])
    %%
    
    ax1 = subplot(4,3,4);

    sign_flip = sign(score((size(score,1)+1)/2,1));
    im_show = sign_flip*plt.saturate(coef2d(:,:,1), saturate);
    imshow(im_show, []);
%     set(im1, 'AlphaData', logical(specs.getMask()))
    colormap(ax1, plt.redblue);  
    caxis([-1,1]*max(abs(im_show(:))));
    
    ht = title("PC1:");
    set(ht, 'position', [-50,50,1])
    
    cb = colorbar();
    cb.Label.String = "Filter ampliture (rel.)";
    cb.Label.Rotation = -90;
    cb.Label.Position = cb.Label.Position + [1,0,0];
    cb.Label.FontSize = 11;
    
    % plotAxisAsImage(ax1)
    
    ax = subplot(4,3,5);
    ts = (0:(length(score) - 1))/specs.getFps();
    ts = ts - mean(ts);
    plot(ts, sign_flip*score(:,1), 'LineWidth', 1.5); xlim(minmax(ts))
    grid off;
    % ax.YGrid = 'off';
    % xticks(-0.4:0.2:0.4)
%     xlim(tlim); 
    % xlabel("Time (s)"); 
    ylabel("Filter amplitude", 'FontSize',11); 
    % set(gca, 'YTickLabels', []);
    
    ax = subplot(4,3,6);
    z1 = abs(fft(score(:,1)));
    fs = linspace(0, specs.getFps(), length(z1)); 
    z1(fs < frange(1) | fs > frange(2)) = NaN;
%     plot(fs, sqrt(z1/median(z0)), 'LineWidth', 1.5);
    semilogy(fs, sqrt(z1), 'LineWidth', 1.5); 
    % xlabel("Frequency (Hz)");
    xlim([0, specs.getFps()/2]); 
    % set(gca, 'YTickLabels', []);
    ylabel('Spectral amplitude', 'FontSize',11);
    grid off;
    
    % ax.YAxis.TickLabelFormat
%     ylim([0,0.3001])
%     ax.YAxis.TickValues = [0:0.05:5];
%     ax.XAxis.MinorTickValues = [0:10:150];
%     ax.YAxis.MinorTickValues = [];
    % grid minor;
    %%

    ax2 = subplot(4,3,7);

    sign_flip = sign(score((size(score,1)+1)/2,2));

    im_show = sign_flip*plt.saturate(coef2d(:,:,2), saturate);
    imshow(im_show, []);
%     set(im2, 'AlphaData', logical(specs.getMask()))
    colormap(ax2, plt.redblue); %caxis([-1,1]*max(abs([min(im_show(:)), max(im_show(:))])));
    caxis([-1,1]*max(abs(im_show(:))));
    
    cb = colorbar();
    cb.Label.String = "Filter ampliture (rel.)";
    cb.Label.Rotation = -90;
    cb.Label.Position = cb.Label.Position + [1,0,0];
    cb.Label.FontSize = 11;
    
   
    ht = title("PC2:");
    set(ht, 'position', [-50,50,1])
       
    ax = subplot(4,3,8);
    plot(ts, sign_flip*score(:,2), 'LineWidth', 1.5); xlim(minmax(ts)); 
    % set(gca, 'YTickLabels', []);
    ylabel("Filter amplitude", 'FontSize',11); 
%     xlim(tlim)
    
    grid off;
    % ax.YGrid = 'off';
    
    ax = subplot(4,3,9);
    z2 = abs(fft(score(:,2)));
    z2(fs < frange(1) | fs > frange(2)) = NaN;
%     z2 = pmtm(score(:,2), nw);
%     plot(fs, sqrt(z2/median(z0)), 'LineWidth', 1.5); 
    semilogy(fs, z2, 'LineWidth', 1.5); 
    % xlabel("Frequency (Hz)"); 
    xlim([0, specs.getFps()/2   ]); 
    ylabel('Spectral amplitude', 'FontSize',11);
    grid off;
    
    ax.XAxis.MinorTickValues = [0:10:150];
    ax.YAxis.MinorTickValues = [];
    % grid minor;
    %%
    
    ax2 = subplot(4,3,10);

    sign_flip = sign(score((size(score,1)+1)/2,3));

    im_show = plt.saturate(sign_flip*coef2d(:,:,3), saturate);
    imshow(im_show, []);
%     set(im3, 'AlphaData', logical(specs.getMask()))
    colormap(ax2, plt.redblue); 
    caxis([-1,1]*max(abs(im_show(:))));
    
    cb = colorbar();
    cb.Label.String = "Filter ampliture (rel.)";
    cb.Label.Rotation = -90;
    cb.Label.Position = cb.Label.Position + [1,0,0];
    cb.Label.FontSize = 11;
    
    ht = title("PC3:");
    set(ht, 'position', [-50,50,1])
    
    ax = subplot(4,3,11);
    plot(ts, sign_flip*score(:,3), 'LineWidth', 1.5); xlim(minmax(ts)); 
    xlabel("Time (s)", 'FontSize',11);
    % set(gca, 'YTickLabels', []);
    ylabel("Filter amplitude", 'FontSize',11); 
    grid off;
    % ax.YGrid = 'off';
    
    ax = subplot(4,3,12);
    z3 = abs(fft(score(:,3)));
    
    z3(fs < frange(1) | fs > frange(2)) = NaN;
%     plot(fs, sqrt(z1/median(z0)), 'LineWidth', 1.5);
    semilogy(fs, z3, 'LineWidth', 1.5); 
    xlabel("Frequency (Hz)", 'FontSize',11);
    xlim([0, specs.getFps()/2]); 
    % set(gca, 'YTickLabels', []);
    ylabel('Spectral amplitude', 'FontSize',11);
    grid off;
end