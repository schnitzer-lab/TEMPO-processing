function moviePlotTraceStim(fullpath_movie, regions, varargin)
    
    [basepath, filename, ext, basefilename, channel, postfix] = ...
        filenameParts(fullpath_movie);

    options = defaultOptions(basepath);
    if(~isempty(varargin))
        options = getOptions(options, varargin);
    end
    %%
    
    if (~isfolder(options.processingdir)) mkdir(options.processingdir); end
  
    %%
    
    disp("moviePlotTraceStim: reading movie")

    [M,specs] = rw.h5readMovie(fullfile(basepath, filename + ".h5"));
    
    if(~isempty(specs.getMask()))
        nan_mask = double(specs.getMask()); nan_mask(~nan_mask) = NaN;
        M = M.*nan_mask;
    end    
    %%
    
    disp("moviePlotTraceStim: getting region trace")
    
    if(~iscell(regions)) regions = num2cell(regions); end
%     region_name = region_names(1);
    for i_r = 1:length(regions)
        region_name = regions{i_r};
        if(ischar(region_name)) region_name = string(region_name); end

        %%
        fig_roi = plt.getFigureByName('roi');
        if(isnumeric(region_name))
            for i_c = 1:length(region_name)
                contours{i_c} = specs.getAllenOutlines(region_name(i_c));
            end
            region_name = strjoin(string(region_name),'+');
            [m_reg, mask_reg] = movieRegion2Trace(M, ...
                contours, 'switchxy', false, 'plot', true);
       else
            if(region_name == "mean")
                m_reg = squeeze(mean(M, [1,2], 'omitnan'));
            else
                [m_reg, mask_reg] = ...
                    movieRegion2Trace(M, ...
                        specs.getAllenOutlines(options.regions_map(region_name)), ...
                        'switchxy', false, 'plot', true);
            end
        end
        
        %%        
        fullpath_out = fullfile(options.processingdir, filename+"_"+string(region_name)+"_stim"+"_"+options.align_to+".h5");
        if(isfile(fullpath_out))
            if(options.skip)
                disp("moviePlotTraceStim: output file exists. Skipping: " + fullpath_out)
                return;
            else
                warning("moviePlotTraceStim: output file exists. Deleting: " + fullpath_out);
                delete(fullpath_out);
            end   
        end

        %%

        saveas(fig_roi, fullfile(options.processingdir, filename+"_"+region_name+"_roi.fig"))
        saveas(fig_roi, fullfile(options.processingdir, filename+"_"+region_name+"_roi.png"))
    
        ttl_signal = specs.getTTLTrace(size(M,3));
        %%
        %%
        fig_traces = plt.getFigureByName("moviePlotTraceStim: traces"); clf;
        
        plt.tracesComparison([ttl_signal/2,  m_reg/std(m_reg)], ...
            'fps', specs.getFps(), 'spacebysd', 2, 'fw', 0.5)
        legend(["ttl", region_name+" raw"], 'Interpreter', 'none')
        
        sgtitle({basepath, filename+" "+region_name}, ...
            'Interpreter', 'none', 'FontSize', 12)
        
        saveas(fig_traces, fullfile(options.processingdir, filename+"_"+region_name+"_traces.fig"))
        saveas(fig_traces, fullfile(options.processingdir, filename+"_"+region_name+"_traces.png"))
        %%
    
        disp("moviePlotTraceStim: getting single-trial traces")
    
        [m_stim,window_stim, intervals_stim] = signalTrials(m_reg, ttl_signal, ...
            'drop', 2, 'iti_scale', options.iti_scale, 'align_to_end', options.align_to=="offset");
        %%
        
        rw.h5saveMovie(fullpath_out, m_stim, specs);
        %%
        m_stim = m_stim - mean(m_stim,2);
        
        %%
        
        fig_stim = plt.getFigureByName("moviePlotTraceStim: traces arranged");
        fig_stim.Position(3:4) = [600,600];
        plt.signalTrials(m_stim, window_stim, specs.getFps(), options.align_to)

%         ts = ((0:(size(m_stim,2) - 1)) - ...
%               sum(window_stim == 0)/2 -...
%               (options.align_to=="offset")*sum(window_stim == 1) )/specs.getFps();
%         
%         fig_stim = plt.getFigureByName("moviePlotTraceStim: traces arranged");
%                   
%         subplot(5,1,1)
%         plot(ts, -mean(m_stim, 1)*100, 'black', 'LineWidth', 1.5);  hold on;
%         plot(ts, -mean(m_stim, 1)*100+std(m_stim,[], 1)*100, 'black--', 'LineWidth', .5);
%         plot(ts, -mean(m_stim, 1)*100-std(m_stim,[], 1)*100, 'black--', 'LineWidth', .5); hold off
%         xlim(minmax(ts));
%         ylabel("-\Delta F/F_0 (%)") ;
%         cb = colorbar; cb.Visible = 'off';
%         
%         subplot(5,1,2:5);
%         imagesc(ts, 1:size(m_stim,1), -plt.saturate(m_stim, 0.00025)*100); colormap(plt.redblue)
%         cb = colorbar; cb.Label.String = "-\Delta F/F_0 (%)"; caxis([-1,1]*max(abs(cb.Limits)));
%         caxis();
%         set(gca,'YDir','normal');
%         
%         xlabel("Time relative to stimulus "+options.align_to+" (s)")
%         ylabel("Trial number")
        
        sgtitle({basepath, filename + " " + region_name}, 'Interpreter', 'none', 'FontSize', 12)
        fig_stim.Position(3:4) = [600,600];
        
        saveas(fig_stim, fullfile(options.processingdir, filename+"_"+region_name+"_stim"+"_"+options.align_to+".fig"))
        saveas(fig_stim, fullfile(options.processingdir, filename+"_"+region_name+"_stim"+"_"+options.align_to+".png"))
        %%

        tb = 120;
        [wt1,frq1,coi]= cwt(double(m_reg),'TimeBandwidth ', tb, 'VoicesPerActave', 16);
        wt1 = abs(wt1)./sqrt(frq1);
        wt1(coi' > frq1) = NaN;
        tscale = 1;
        
%         noise_trace = randn(size(M,3),1);
%         A_noise = noiseAmplitudeDFF(specs);  
%         noise_sd = mean(A_noise(mask_reg), 'omitnan')/sqrt(sum(mask_reg(:), 'omitnan'));
% 
%         [wt_noise, fnoise, coi_noise] = cwt(noise_trace*noise_sd,'TimeBandwidth ', tb, 'VoicesPerActave', 16);
%         wt_noise = abs(wt_noise)./sqrt(fnoise);
%         wt_noise(coi_noise' > fnoise) = NaN;
%         wt_noise_limit = median(wt_noise(:), 'omitnan');
%         
        % nw = 64;
        % [wt1,frq1] = spectrogram(m0_reg,hamming(nw).^2,round(7/8*nw));
        % frq1 = frq1/pi/2;
        % wt1 = abs(wt1);
        % 
        % tscale = size(wt1,2)/length(m1_reg);
        
        %%
        
        [wt_trial, window_stim1] = signalTrials(wt1, ....
            interp1(1:length(ttl_signal), single(ttl_signal), (1:size(wt1,2))/tscale)', ...
            'drop', 3, 'iti_scale', options.iti_scale/2, ...
            'align_to_end', options.align_to=="offset");
        
        window_stim1((max(find(window_stim1 == 1))+1):end) = 2;
        
        stim_onset_frame = min(find(window_stim1 == 1));
        stim_offset_frame = max(find(window_stim1 == 1)+1); 
        %%
        
        f_start = 1.5;
        nframes_average = round(0.5*specs.getFps());
        
        fs = frq1*specs.getFps();
        
        fig_spect = plt.getFigureByName('moviePlotTraceStim: spectras');
        
        semilogy(fs(fs>f_start), mean(wt_trial(:,fs>f_start,window_stim1==0),[1,3], 'omitnan'), '.-'); hold on;
        semilogy(fs(fs>f_start), mean(wt_trial(:,fs>f_start,window_stim1==1),[1,3], 'omitnan'), '.-'); hold on;
        semilogy(fs(fs>f_start), mean(wt_trial(:,fs>f_start,stim_onset_frame: (stim_onset_frame+nframes_average)),[1,3], 'omitnan'), '.-'); hold on;
        semilogy(fs(fs>f_start), mean(wt_trial(:,fs>f_start,stim_offset_frame:(stim_offset_frame+nframes_average)),[1,3], 'omitnan'), '.-'); hold on;
        % yline(wt_noise_limit)
        hold off;
        
        legend(["pre"+" ("+string(round(sum(window_stim1==0)/specs.getFps(),1)) + "s)", ...
                "stim"+" ("+string(round(sum(window_stim1==1)/specs.getFps(),1)) + "s)",...
                "post onset"+" ("+string(round(nframes_average/specs.getFps(),1)) + "s)",... 
                "post offset"+" ("+string(round(nframes_average/specs.getFps(),1)) + "s)"]);
        xlabel("Frequency (Hz)");
        ylabel("Wavelet amplitude (arb.u.)")
        title({basepath, filename + " " + region_name}, 'Interpreter', 'none', 'FontSize', 12)
        
        saveas(fig_spect, fullfile(options.processingdir, filename+"_"+region_name+"_trialspectra"+"_"+options.align_to+".fig"))
        saveas(fig_spect, fullfile(options.processingdir, filename+"_"+region_name+"_trialspectra"+"_"+options.align_to+".png"))
        %%
        
        
        wt = squeeze(mean(wt_trial, 1, 'omitnan'));% - wt_noise_limit;
        wt_plot = (wt-quantile(wt',0.01)')./quantile(wt',.05)';
        
        ts1 = ((0:(size(wt_plot,2)-1)) -...
               sum(window_stim1==0)-...
               (options.align_to=="offset")*sum(window_stim1 == 1))/specs.getFps()/tscale;
        
        fig_spec = plt.getFigureByName('moviePlotTraceStim: CWT');
        
        
%         cs = [0,500];%
        cs = quantile( wt_plot(:)*100, [0.01,0.99], 'all');%
        hpc = pcolor(ts1, frq1*specs.getFps(),  wt_plot*100); 
        set(hpc, 'EdgeColor', 'none');
        ax_spec = gca();
        caxis(cs');
        % coi' < frq
        
        cb = colorbar;
        cb.FontSize = 12;
        cb.Label.String = ["Change of wavelet magnitude (%)"];
        cb.Label.FontSize = 15;
        cb.TickLength = 0.02;
        
        ax_spec.FontSize = 13;
        xlabel("Time relative to stimulus "+options.align_to+" (s)", 'FontSize', 15)
        ylabel('Frequency (Hz)', 'FontSize', 15)
        % xticks(-2:0.25:2); xlim([-1.25,1.25]);
        colormap('jet')
%         set(gca, 'ColorScale', 'Log')
        
        title({basepath, filename + " " + region_name}, 'Interpreter', 'none', 'FontSize', 12)
        fig_spec.Position = [fig_spec.Position(1:2), 500,400];
        ax_spec.OuterPosition = [0,0,0.98,1];
        
        saveas(fig_spec, fullfile(options.processingdir, filename+"_"+region_name+"_spectrogram"+"_"+options.align_to+".fig"))
        saveas(fig_spec, fullfile(options.processingdir, filename+"_"+region_name+"_spectrogram"+"_"+options.align_to+".png"))
        % saveas(fig_spec, fullfile(outdir, filename0+"_"+region_name+"_spectrogram"+"_"+align_to+".eps"), 'epsc')
        saveas(fig_spec, fullfile(options.processingdir, filename+"_"+region_name+"_spectrogram"+"_"+options.align_to), 'epsc')
        %%
    end
end
%%

function options = defaultOptions(basepath)
    
    options.align_to = "offset"; % "onset" or "offset"
    options.regions_map = ...
        containers.Map(["M1", "SSp-bfd", "SSp-ll", "V1", "RSP"], [4,10, 12,38,51]);

    options.skip = true;
    options.iti_scale = 1;
    options.processingdir = basepath + "\processing\plotTraceStim\";

end
%%