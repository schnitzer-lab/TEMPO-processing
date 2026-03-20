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
    
    if(options.lag_estimator == "phase")
        nfft = 2^(ceil(log2(options.max_lag_frames*pi)));
        noverlap = round(nfft*4/5); 
        pxy = cpsd(m_in, m_ref, hann(nfft), noverlap, nfft);
    
        fs = linspace(0,specs.getFps()/2, length(pxy));
%         pxy(cohxy < 0.1) = NaN; % then unwrapping woudn't work
        pxy(fs < options.f0) = NaN;
        
        relative_phase = unwrap(angle(pxy))/2/pi;
        %%

        df = [0; diff(relative_phase)];
        df(isnan(df)) = 0;
        df(abs((df - mean(df, 'omitnan'))./std(df, [], 'omitnan')) > 3) = mean(df, 'omitnan');
        relative_phase_filtered = cumsum (df);

        relative_phase_filtered(isnan(relative_phase)) = NaN;
        %%

        coefs = robustfit(fs, relative_phase_filtered, 'welsch', 1, 'on');
        lag = -coefs(2)*specs.getFps();
        %%
        
        fig_phase = plt.getFigureByName("movieCompensateDelay: phase");
        plot(fs, relative_phase_filtered);
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
        m_in_hp = highpass(m_in, options.f0, specs.getFps());
        m_ref_hp = highpass(m_ref, options.f0, specs.getFps());
        [lag, r, lags, xc] = ...
            xcorrLagFFT(m_in_hp(100:(end-100)), m_ref_hp(100:(end-100)), ...
            50, options.max_lag_frames, true);
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

        displog("correcting timeshift");
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
    
    options.diagnosticdir = fullfile(basepath, 'diagnostic', 'moviesCompensateDelay');
    options.outdir = basepath;
    options.skip = true;

    options.min_lag_frames = 0.5;
    options.max_lag_frames = 100;

    options.f0 = 30;

    options.lag_estimator = "phase"; % "phase" or "xcorr"
end
%%