function [fullpath_out,lag] = ...
    movieCompensateDelay(fullpath_movie, fullpath_movie_ref, varargin)
    
    [basepath, filename, ext, basefilename, channel, postfix] = ...
        filenameParts(fullpath_movie);

    options = defaultOptions(basepath);
    if(~isempty(varargin))
        options = getOptions(options, varargin);
    end
    %%
    
    if (~isfolder(options.outdir)) mkdir(options.outdir); end
    if (~isfolder(options.diagnosticdir)) mkdir(options.diagnosticdir); end
    %%

    fullpaths_in_mean = movieMeanTraces([fullpath_movie_ref, fullpath_movie]);
    m_ref = rw.h5getMeanTrace(fullpaths_in_mean(1));
    m_in  = rw.h5getMeanTrace(fullpaths_in_mean(2));
    specs = rw.h5readMovieSpecs(fullpath_movie);
    %%

    if(options.bandpass && isempty(options.f_bp))
        
        nw = 0.5*length(m_in)/specs.getFps()/2;
        z = pmtm(m_in, nw); 
        fs = linspace(0, specs.getFps()/2, length(z));
        z(fs < options.f0) = NaN;  %discard low-frequency stuff
        [pks,locs,w,p] = findpeaks(log(z), 2*length(z)/specs.getFps(),...
            'MinPeakWidth', 0.3, 'MinPeakProminence', 0.5, 'SortStr', 'descend','Annotate','extents');
    
        options.f_bp = 2*round(locs(1),1);  %2d harmonic - less obsuced under anesthesia
        options.w_bp = ceil(w(1)*10)/10;
    end      
    %%

    if(options.bandpass)  
        options_bandpass = struct( 'attn', 1e4, 'rppl', 1e-2,  'skip', options.skip, ...
            'filtersdir', "P:\GEVI_Wave\ConvolutionFilters\", ...
            'exepath', "C:\Users\Vasily\repos\VoltageImagingAnalysis\analysis\c_codes\compiled\hdf5_movie_convolution.exe",...
            'num_cores', 22);   
        
        fullpath_bp = movieFilterExternalBandpass(fullpaths_in_mean(1), ...
            options.f_bp, options.w_bp, options_bandpass);
        fullpath_ref_bp = movieFilterExternalBandpass(fullpaths_in_mean(2), ...
            options.f_bp, options.w_bp, options_bandpass);
        
        m_in = rw.h5getMeanTrace(fullpath_bp);
        m_ref = rw.h5getMeanTrace(fullpath_ref_bp);
    end
    %%
    
    if(options.lag_estimator == "phase")
        nfft = 2^(ceil(log2((specs.getFps()/2) / 1))); %1Hz bin
        noverlap = round(nfft/2); 
%         cohxy = mscohere(m_in(options.ndrop:(end)), m_ref((options.ndrop):end), ...
%             hann(nfft),noverlap,nfft);
        pxy = cpsd(m_in(options.ndrop:(end)), m_ref((options.ndrop):end), ...
            hann(nfft),noverlap,nfft); % Plot estimate
    
        fs = linspace(0,specs.getFps()/2, length(pxy));
%         pxy(cohxy < 0.1) = NaN; % then unwrapping woudn't work
        pxy(fs < options.f0) = NaN;
        
        relative_phase = unwrap(angle(pxy))/2/pi;
        %%
        coefs = robustfit(fs, relative_phase, 'welsch', 1, 'on');
        lag = -coefs(2)*specs.getFps();
%%
        fig_phase = plt.getFigureByName("movieCompensateDelay: phase");
        plot(fs, relative_phase);
        hold on
        plot(fs, coefs(1) + coefs(2)*fs)
        hold off
        legend(["phase", "\tau="+num2str(lag/specs.getFps()*1000, '%.1f')+"ms="+num2str(lag, '%.1f')+"frames"])
        xlabel("f (Hz)"); ylabel("Phase \phi/2\pi (rel.)")
        saveas(fig_phase, fullfile(options.diagnosticdir, filename + "_phase.png"))
        saveas(fig_phase, fullfile(options.diagnosticdir, filename + "_phase.fig"))
    end
    %%
    
    if(options.lag_estimator == "xcorr")
        %%
        [lag, r, lags, xc] = ...
            xcorrLagFFT(m_in(options.ndrop:end), m_ref(options.ndrop:end), 50, specs.getFps(), true);
        %%
    
        fig_mean = plt.getFigureByName("moviesCompensateDelay: mean traces initial");
        plt.tracesComparison([m_in, m_ref], 'fps', specs.getFps(), 'fw', 0.25);
        saveas(fig_mean, fullfile(options.diagnosticdir, filename + "_mean_init.png"))
        saveas(fig_mean, fullfile(options.diagnosticdir, filename + "_mean_init.fig"))
        
        fig_corr = plt.getFigureByName("moviesCompensateDelay: correlation");
        plot(lags,xc); xlabel('frame delay'); ylabel('correlation');
        xlim([-100,100]); grid on;
        xline(lag, 'red'); title("Lag " + num2str(lag, '%.1f') + " frames, r=" + num2str(r, '%.2f'));   
        saveas(fig_corr, fullfile(options.diagnosticdir, filename + "_corr.png"))
        saveas(fig_corr, fullfile(options.diagnosticdir, filename + "_corr.fig"))
    end
    %%

    fullpath_out = fullpath_movie;
    if(abs(lag) > options.min_lag_frames)

        disp("moviesCompensateDelay: correcting timeshift");
        fullpath_out = movieDelay(fullpath_movie, -lag/specs.getFps(), 'frame0', 20,...
            'outdir', options.outdir);

        m_out = rw.h5getMeanTrace(fullpath_out); 
        m_in  = rw.h5getMeanTrace(fullpaths_in_mean(1));
        m_ref = rw.h5getMeanTrace(fullpaths_in_mean(2));
        
        fig_mean = plt.getFigureByName("moviesCompensateDelay: mean traces final");
        plt.tracesComparison([m_in, m_ref, m_out], 'fps', specs.getFps(), 'fw', 0.25, ...
            'labels', ["in", "ref", "shifted"]);
        saveas(fig_mean, fullfile(options.diagnosticdir, filename + "_mean_out.png"));
        saveas(fig_mean, fullfile(options.diagnosticdir, filename + "_mean_out.fig"));
        end
end
%%

function options = defaultOptions(basepath)
    
    options.diagnosticdir = basepath + "\diagnostic\moviesCompensateDelay\";
    options.outdir = basepath;
    options.skip = true;

    options.min_lag_frames = 0.5;

    options.bandpass = false;
    options.f_bp = [];
    options.w_bp = 1; %Hz
    
    options.f0 = 1.5;

    options.lag_estimator = "phase"; % "phase" or "xcorr"
    
    options.ndrop = 20;
end
%%