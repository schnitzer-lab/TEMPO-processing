
function unmixingFilterPCA(W, specs, n_pcs)
%%
    saturate = 0.01;
    if(nargin < 3),  n_pcs = 6; end

%%

    w = squeeze(mean(W, [1,2], 'omitnan'));
    % sign0 = sign(w( ceil((numel(w)+1)/2) ));
    sign0 = sign(mean(w));
    frange = specs.getFrequencyRange();

    % non-centered PCA without substracting the mean. Basicaly, relative to
    % 0, that is the first PC1 jenerally points towards the mean. Makes it 
    % easy to compare PC1 (~= mean) to the contribution of other PCs
    Win = W;%-reshape(w, [1,1,length(w)]);%-mean(W, 3);
    Win(isnan(Win)) = 0;
    
    [spatialpc,temporalpc,latent] = ...
        pca(reshape(Win, [prod(size(Win, [1,2])), size(Win,3)])');
        
%     (Win - reshape(spatialpc*temporalpc', size(Win))) == 0
    
    % coefficients are scaled to be comparible to the average trace, but
    % thus no longer multiply to the total

    % score = temporalpc;
    % coeff = spatialpc;

    weight = sqrt(sum(temporalpc.^2, 1)).*sqrt(mean(spatialpc.^2,1));
    varpercent = weight.^2 ./ sum(weight.^2);
    
    score = temporalpc .* sqrt(mean(spatialpc.^2,1));
    coeff = spatialpc ./ sqrt(mean(spatialpc.^2,1));
    
    % coeff = coeff .* sqrt(mean(spatialpc.^2,1)) .* sqrt(sum(temporalpc.^2, 1));

    % score = temporalpc ./ sqrt(sum(temporalpc.^2, 1));
    % coeff = spatialpc .* sqrt(sum(temporalpc.^2, 1));

    coef2d = reshape(coeff, [size(Win, [1,2]), size(coeff, 2)]);
%     coef2d(repmat(nanmask, [1,1, size(coef2d, 3)])) = NaN;
%%

    n_rows = n_pcs + 1;

    ax1 = subplot(n_rows,3,1);

    im_show = plt.saturate(sqrt(sum(Win.^2,3)), saturate);
    im1 = imshow(im_show, []);
    if(~isempty(specs.getMask()))
        set(im1, 'AlphaData', logical(specs.getMask()))
    end
    colormap(ax1, plt.redblue);  
    caxis([-1,1]*max(abs(im_show(:))));
    
    ht = title(["filter:"]);
    set(ht, 'position', [-50,50,1])
    
    cb = colorbar();
    cb.Label.String = "Total filter amplitude";
    cb.Label.Rotation = -90;
    cb.Label.Position = cb.Label.Position + [1,0,0];
    cb.Label.FontSize = 11;

    ax = subplot(n_rows,3,2);
    ts = (0:(length(w) - 1))/specs.getFps();
    ts = ts - mean(ts)-1/specs.getFps()/2;
    plot(ts, w, 'LineWidth', 1.5); %xlim(minmax(ts))
    xlim( [-1,1]*max(abs(ts)) ); 
    ylabel("Filter amplitude", 'FontSize',11); 
    % grid on;
    % title("Time-domain filter")
    % grid OFF;
    grid on; ax.XMinorGrid = 'on'; ax.YGrid = 'off';
    
    ax = subplot(n_rows,3,3);
    zw = abs(fft(w));
    fs = linspace(0, specs.getFps(), length(zw)); 
    zw(fs < frange(1) | fs > frange(2)) = NaN;
    semilogy(fs, zw, 'LineWidth', 1.5); xlim(minmax(fs)); 

    grid on; ax.XMinorGrid = 'on';
    xticks([0:10:specs.getFps()]);
    xlim([0, specs.getFps()/2]);
    ylabel('Spectral amplitude', 'FontSize',11);
    %%
    
    ts  = (0:(size(score,1) - 1))/specs.getFps();   ts = ts - mean(ts);
    fs  = linspace(0, specs.getFps(), size(score,1));
    fps = specs.getFps();

    % Create the axes here (change this layout to rearrange the plots), then
    % hand each row its three axes [map, trace, spectrum] to plotPCRow.
    % Rows 2..n_rows hold the PCs; row 1 is the average filter (above).
    axs = gobjects(n_pcs, 3);
    for i_pc = 1:n_pcs
        base = 3*i_pc;   % subplot index of the previous (average/PC) row's end
        axs(i_pc,:) = [subplot(n_rows,3,base+1), ...
                       subplot(n_rows,3,base+2), ...
                       subplot(n_rows,3,base+3)];
    end

    for i_pc = 1:n_pcs
        %%
        plotPC(coef2d(:,:,i_pc), score(:,i_pc), axs(i_pc,:), ...
            ts, fs, frange, fps, sign(w'*score(:,i_pc)), saturate, ...
            ["PC"+ num2str(i_pc) , ...
             sprintf("%.1f%% var", 100*varpercent(i_pc))]);
    end

    % bottom-row axis labels
    xlabel(axs(end,2), "Time (s)", 'FontSize',11);
    xlabel(axs(end,3), "Frequency (Hz)", 'FontSize',11);
end

function plotPC(coef_map, trace, ax, ts, fs, frange, fps, sign_flip, saturate, titlestr)
%% Plot one principal-component row into the three supplied axes:
%   ax(1) spatial map | ax(2) time trace | ax(3) spectrum
    % sign_flip = sign(trace( ceil((numel(trace)+1)/2) ))*sign0;
    % sign_flip = sign(mean(trace))*sign0;

    % --- spatial map ---
    im_show = sign_flip*plt.saturate(coef_map, saturate);
    imshow(im_show, [], 'Parent', ax(1));
    colormap(ax(1), plt.redblue);
    caxis(ax(1), [-1,1]*max(abs(im_show(:))));

    ht = title(ax(1), titlestr);
    set(ht, 'position', [-size(im_show,1)/2,size(im_show,2)/3,1])

    cb = colorbar(ax(1));
    cb.Label.String = "Filter ampliture (rel.)";
    cb.Label.Rotation = -90;
    cb.Label.Position = cb.Label.Position + [1,0,0];
    cb.Label.FontSize = 11;

    % --- time-domain trace ---
    plot(ax(2), ts, sign_flip*trace, 'LineWidth', 1.5); xlim(ax(2), minmax(ts));
    ylabel(ax(2), "Filter amplitude", 'FontSize',11);
    grid(ax(2), 'on'); ax(2).XMinorGrid = 'on'; ax(2).YGrid = 'off';

    % --- spectrum ---
    z = abs(fft(trace));
    z(fs < frange(1) | fs > frange(2)) = NaN;
    semilogy(ax(3), fs, z, 'LineWidth', 1.5);
    grid(ax(3), 'on'); ax(3).XMinorGrid = 'on';
    xticks(ax(3), [0:10:fps]);
    xlim(ax(3), [0, fps/2]);
    ylabel(ax(3), 'Spectral amplitude', 'FontSize',11);
end