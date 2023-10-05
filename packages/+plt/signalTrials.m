function signalTrials(m_stim, window_stim, fps, align_to)
    
     ts = ((0:(size(m_stim,2) - 1)) - ...
              sum(window_stim == 0)/2 -...
              (align_to=="offset")*sum(window_stim == 1) )/fps;        
              
    subplot(5,1,1)
    plot(ts, -mean(m_stim, 1)*100, 'black', 'LineWidth', 1.5);  hold on;
    plot(ts, -mean(m_stim, 1)*100+std(m_stim,[], 1)*100, 'black--', 'LineWidth', .5);
    plot(ts, -mean(m_stim, 1)*100-std(m_stim,[], 1)*100, 'black--', 'LineWidth', .5); hold off
    xlim(minmax(ts));
    ylabel("-\Delta F/F_0 (%)") ;
    cb = colorbar; cb.Visible = 'off';
    
    subplot(5,1,2:5);
    imagesc(ts, 1:size(m_stim,1), -plt.saturate(m_stim, 0.00025)*100); colormap(plt.redblue)
    cb = colorbar; cb.Label.String = "-\Delta F/F_0 (%)"; caxis([-1,1]*max(abs(cb.Limits)));
    caxis();
    set(gca,'YDir','normal');
    
    xlabel("Time relative to stimulus "+align_to+" (s)")
    ylabel("Trial number")

end