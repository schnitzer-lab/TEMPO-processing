function [fullpath_out, fullpathWxy_out, fullpathWsm_out]  = ...
    movieEstimateHemoGFiltTR2(fullpath_sig, fullpath_ref, varargin)
    
    [basepath_ref, ~, ~] = fileparts(fullpath_ref);

    options = defaultOptions(basepath_ref);
    if(~isempty(varargin))
        options = getOptions(options, varargin);
    end
    %%

    [fullpath_out, fullpathWxy_out, fullpathWsm_out, do_skip] = ...
        setupOutput(fullpath_sig, fullpath_ref, options);
    if(do_skip), return; end
    [~,filename_out,~] = fileparts(fullpath_out);
    %%
    
    disp("movieEstimateHemoGFiltTR: loading mean traces")
        
    % To avoid extra data in the ram, movies are loaded from hard drive
    % when passed to processing functions 
    specs_r = rw.h5readMovieSpecs(fullpath_ref);
    [nx,ny,nt] = rw.h5getDatasetSize(fullpath_ref, '/mov');
    mr = rw.h5getMeanTrace(fullpath_ref);
    mg = rw.h5getMeanTrace(fullpath_sig);
    %%
       
    wn = round(specs_r.getFps()*options.dt);
    if(mod(wn,2) == 0), wn = wn+1; end % unnecessary, but nice for plotting
    no = round(wn*options.overlap);

    wn_chunk = round(specs_r.getFps()*options.dt_slow);
    if(wn_chunk > length(mr)), wn_chunk = length(mr); end
    dn_chunk =  round(wn_chunk*(1-options.overlap));
    [chunks, chunks_nooverlap] = formchunks(length(mr), wn_chunk, dn_chunk);

    frefs = []; zs = [];
    if(isempty(options.fref))
        % find first hemodynamic peak
        for i_ch = 1:size(chunks,1)
            mr_chunk = mr(chunks(i_ch,1):chunks(i_ch,2));
        
            [~,locs,~, ~, z] = findpeaksspectral(mr_chunk, options.fref_resolution, ...
                specs_r.getFps(), options.fref_lims,...
                'MinPeakWidth', options.fref_minpeakwidth, ...
                'MinPeakProminence', options.fref_minpeakprominance, 'SortStr', 'descend');
            if(~isempty(locs)), frefs(i_ch) = locs(1);
            else, frefs(i_ch) = NaN; end
            zs(i_ch, :) = z;
        end
    else
        frefs = options.fref;
    end
    if(length(frefs) > 1)
        ind = 1:length(frefs);
        frefs = interp1(ind(~isnan(frefs)), frefs(~isnan(frefs)), ind, 'linear', 'extrap');
    end
    if(any(isnan(frefs))), error('movieEstimateHemoGFiltTR: NaN reference freq'); end

    options_limit = struct(...
        'fref', frefs/specs_r.getFps(), 'max_amp_rel', options.max_amp_rel, ...
        'flim_max', options.flim_max/specs_r.getFps(), ...
        'max_phase', options.max_phase, 'max_delay', options.max_delay*specs_r.getFps() );
    
    if(isempty(options.naverage))
        options.naverage = round(options.average_mm/specs_r.getPixSize()/2)*2+1;
    end
    %%

    disp("movieEstimateHemoGFiltTR: loading ref and performing spatial averaging")


    Mr = rw.h5readMovie(fullpath_ref);
    Mg = rw.h5readMovie(fullpath_sig);
    %%

    options_estimate_nolim = copyStruct(options_limit);
    options_estimate_nolim.max_delay = Inf; options_estimate_nolim.max_amp_rel = Inf;
    %%
    
    w0 = 0; Mr_filt0 = 0;
    if(options.mean_to_mean)
        w0 = estimateFiltersTimeResolved(...
            reshape(mg, 1,1,[]), reshape(mr, 1,1,[]), ...
            wn, no, chunks, frefs/specs_r.getFps());
        w0 = limitFiltersTimeResolved(w0, options_limit);
        Mr_filt0 = applyFiltersTimeResolved(...
            Mr, repelem(w0, size(Mr,1), size(Mr,2)), chunks, chunks_nooverlap);
    end
    %%

    disp("movieEstimateHemoGFiltTR: estimating filter for averaged traces")
    
    Wxy = w0 + estimateFiltersTimeResolved(Mg-Mr_filt0, Mr, ...
        wn, no, chunks, frefs/specs_r.getFps() );
    Wxy = limitFiltersTimeResolved(Wxy, options_limit);
    % clear('Mr_filt0');
    
    Mr_filt = applyFiltersTimeResolved(Mr, Wxy, chunks, chunks_nooverlap); %convn(Mr_in, W0, 'same');
    % clear('Mr_sm');
    %%
   
    disp("movieEstimateHemoGFiltTR: estimating filter for each pixel")

    % local correction in case of ref spatial averaging
    Wsm = 0;
    if( options.naverage > 1 )
        
        if(all([nx,ny] < options.naverage))
            Mr_sm = reshape(repelem(mr, nx*ny), [nx,ny,nz]);
        else
            Mr_sm = rw.h5readMovie(fullpath_ref); 
            
            % NaNs on the ref edges due to registration. Imputing (imputeNaNS) or 
            % nan-tolerant smoothing (smooth2a/mm.movieSmooth) takes forever
            Mr_sm(isnan(Mr_sm)) = 0; 
            Mr_sm = smooth3(Mr_sm, 'box', [options.naverage, options.naverage,1]);
        end

        Mr_filt_xy = Mr_filt;
        Mr_filt_xy(isnan(Mr_filt_xy)) = 0;  % to avoid NaN propagation from the ref channel edges
       
        Wsm = estimateFiltersTimeResolved(...
            Mg - Mr_filt_xy,  Mr_sm, ...
            wn, no, chunks, frefs/specs_r.getFps());   
        Wsm = limitFiltersTimeResolved(Wsm, options_limit);

        Mr_filt = Mr_filt_xy + ...
            applyFiltersTimeResolved(Mr_sm, Wsm, ...
                chunks, chunks_nooverlap);
    
%          is_new_nan = isnan(Mr_filt) & ~isnan(Mr_filt_xy);
%          Mr_filt(is_new_nan) = Mr_filt_xy(is_new_nan);
%          clear('Mr_filt_sm');
    end
    %%
    
    disp("movieEstimateHemoGFiltTR: saving")

    specs_out = copy(specs_r);
    specs_out.AddToHistory(functionCallStruct({'fullpath_sig', 'fullpath_ref', 'options'}));

    rw.h5saveMovie(fullpath_out, Mr_filt, specs_r);
    rw.h5saveMovie(fullpathWsm_out, reshape(Wxy, size(Wxy,1), size(Wxy,2), []), specs_out);
    if(options.naverage > 1) 
        rw.h5saveMovie(fullpathWxy_out, reshape(Wsm, size(Wsm,1), size(Wsm,2), []), specs_out);
    else 
        fullpathWxy_out = []; 
    end   
    %%
    
    disp("movieEstimateHemoGFiltTR: saving plots")
        
    options.fref = mean(frefs);
    savePlots(rw.h5readMovie(fullpath_sig), rw.h5readMovie(fullpath_ref), ...
        Mr_filt, Wxy, specs_r, filename_out, options);
end
%%

function options = defaultOptions(basepath)
    
    options.dt = 2; % s, time window for single filter estimation
    options.overlap = 0.6; % time windows relative overlap 
    
    options.dt_slow = 30; % s, timescale of filter evolution

    options.naverage = []; % number of points for reference ch spatial averaging 
    options.average_mm = Inf; % mm, scale for reference ch spatial averaging 
    options.mean_to_mean = true;

    options.fref = []; % Hz,  main hemodynamic peak frequency
    options.fref_lims = [1.5, 20]; % Hz, limits for finding main hemodynamic peak frequency
    options.fref_resolution = 0.4; % for finding main hemodynamic peak frequency
    options.fref_minpeakwidth = 0.3; % for finding main hemodynamic peak frequency
    options.fref_minpeakprominance = 2; % for finding main hemodynamic peak frequency

    options.max_amp_rel = Inf; % max filter amplitude (across freq) rel to its amplitude @ fref 
    options.max_phase = pi;  % max filter phase (across freq)
    options.max_delay = Inf; % s, max filter delay (across freq)
    options.flim_max = 20; % Hz, maximum frequency below wich the filter limits above apply

    options.diagnosticdir = fullfile(basepath, 'diagnostic', 'hemoFilt');
    options.illustrdir = fullfile(basepath, 'illustrations');
 
    options.outdir = basepath;
    options.postfix_new = "_hemoFiltTR";
    options.skip = true;
end
%%

function [fullpath_out, fullpathWxy_out, fullpathW0_out, do_skip] = ...
    setupOutput(fullpath_sig, fullpath_ref, options)

    [basepath_ref, filename_ref, ext, ~, ch_ref, ~] = filenameParts(fullpath_ref);
    [~, ~, ~, ~, ch_sig, ~] = filenameParts(fullpath_sig);
   
    postfix_new = options.postfix_new + "to"+ch_sig+...
        "dt"+string(round(options.dt,1)) + "dts"+string(round(options.dt_slow,1))+...
        "nav"+num2str(options.naverage) + ...
        "ma"+string(options.max_amp_rel) + "md"+string(round(options.max_delay*1e3));
    
    if (~isfolder(options.outdir)), mkdir(options.outdir); end
    if (~isfolder(options.illustrdir)), mkdir(options.illustrdir); end 
    if (~isfolder(options.diagnosticdir)), mkdir(options.diagnosticdir); end  

    filename_out = filename_ref + postfix_new;
    fullpath_out = fullfile(options.outdir, filename_out + ext);
    fullpathWxy_out = fullfile(options.diagnosticdir, filename_out + "_Wxy" + ext);
    fullpathW0_out = fullfile(options.diagnosticdir, filename_out + "_W0" + ext);
    do_skip = false;    

    if (isfile(fullpath_out))
        if(options.skip)
            disp("movieEstimateHemoGFiltTR: Output file exists. Skipping:" + fullpath_out);
            do_skip = true;
            return;
        else
            warning("movieEstimateHemoGFiltTR: Output file exists. Deleting:" + fullpath_out);
            delete(fullpath_out);
        end     
    end
    
    if(isfile(fullpathWxy_out)), delete(fullpathWxy_out); end
    if(isfile(fullpathW0_out)), delete(fullpathW0_out); end
end

%%

function savePlots(Mg, Mr, Mr_filt, Wxy, specs, filename_out, options)
    
%     Wxy = mean(Wxy, 4);
    Mg(isnan(Mr_filt)) = NaN;
    Mr(isnan(Mr_filt)) = NaN;
    %%

    pix_loc =  round(size(Mr, [1,2])/2);

    w =  squeeze(mean(Wxy(pix_loc(1),pix_loc(2),:,:), [1,2,4], 'omitnan'));
    zw = fft(w);
    fs = linspace(0,specs.getFps, length(zw));
    [~,ind_f0] = min(abs(fs-options.fref));
 
    mg =  squeeze(Mg(pix_loc(1),pix_loc(2),:));
    mr =  squeeze(Mr(pix_loc(1),pix_loc(2),:));
    mr_filt = squeeze(Mr_filt(pix_loc(1),pix_loc(2),:));
    mg_nohemo  = squeeze(Mg(pix_loc(1),pix_loc(2),:)-Mr_filt(pix_loc(1),pix_loc(2),:));
    
    fig_time_pix = plt.getFigureByName("movieEstimateHemoGFiltTR: single pix");

    plt.tracesComparison([mg, mr*abs(zw(ind_f0)), mr_filt, mg-mr*abs(zw(ind_f0)), mg_nohemo], ...
        'labels',["ch1", "ch2 (scaled)", "ch2 (filtered)", "umx regression", "umx filter"],...
        'fps', specs.getFps(), 'fw', 0.2, ...
        'nomean', false, 'spacebysd', [0,3,0,3,0], 'f0', specs.getFrequencyRange(1));
    sgtitle(['pixel ' , sprintf('(%d, %d)', pix_loc(1),  pix_loc(2))]);
    
    saveas(fig_time_pix, fullfile(options.diagnosticdir, filename_out + "_pixtraces" + ".png"))
    saveas(fig_time_pix, fullfile(options.diagnosticdir, filename_out + "_pixtraces" + ".fig"))
    %%
        
%     nan_mask = ones(size(Wxy, [1,2]));
%     if(~isempty(specs.getMask())), nan_mask(specs.getMask() == 0) = NaN; end
    w =  squeeze(mean(Wxy, [1,2,4], 'omitnan'));
    
    zw = fft(w);
    fs = linspace(0,specs.getFps, length(zw));
    [~,ind_f0] = min(abs(fs-options.fref));
      
    fig_time = plt.getFigureByName("movieEstimateHemoGFiltTR: Spatially-averaged traces");
 
    mg =  squeeze(mean(Mg,[1,2],'omitnan'));
    mr =  squeeze(mean(Mr,[1,2],'omitnan'));
    mr_filt = squeeze(mean(Mr_filt,[1,2],'omitnan'));
    mg_nohemo  = squeeze(mean(Mg-Mr_filt, [1,2],'omitnan'));

    plt.tracesComparison([mg, mr*(mr\mg), mr_filt, mg-mr*(mr\mg), mg_nohemo], ...
        'labels',["ch1", "ch2 (scaled)", "ch2 (filtered)", "umx regression", "umx filter"],...
        'fps', specs.getFps(), 'fw', 0.2, ...
        'nomean', false, 'spacebysd', [0,3,0,3,0], 'f0', specs.getFrequencyRange(1));
    sgtitle('spatially averaged');
    
    saveas(fig_time, fullfile(options.diagnosticdir, filename_out + "_meantraces" + ".png"))
    saveas(fig_time, fullfile(options.diagnosticdir, filename_out + "_meantraces" + ".fig"))
    %%

    W =  squeeze(mean(Wxy, [1,2], 'omitnan'));
    w = mean(W,2);
    ZW = fft(W);
    zw = mean(ZW,2);
    zw(fs < specs.getFrequencyRange(1)) = NaN;

    ts = ((1:length(w))-(length(w)+1)/2)/specs.getFps();

    fig_filt= plt.getFigureByName("movieEstimateHemoGFiltTR: Spatially-averaged filter");
    fig_filt.Position(4) = 630;
    
    sgtitle('Unmixing filter')
    subplot(3,1,1)
    plot( ts, w, 'LineWidth', 1.5);
    legend('time representation'); grid();
    xlabel('Time, s'); xlim(minmax(ts))

    subplot(3,1,2)

%     semilogy(fs, abs(ZW), ':')
    semilogy(fs, abs(zw), '.-', 'LineWidth', 1.5); xlim([0, specs.getFps()/2]);
    hold on;
    grid();

    legend(["spectral amplitude"]);

    if(options.max_amp_rel < inf)
        line([0, options.flim_max], ...
             [1, 1]*options.max_amp_rel*abs(zw(ind_f0)), ...
            'LineStyle', '--', 'Color', 'black', 'LineWidth', 1);
        hold on;
        scatter(options.fref, abs(zw(ind_f0)), 'o')
        hold off;

        legend(["spectral amplitude", ...
            "limit ("+num2str(options.max_amp_rel)+"*ref)", "reference"]);
    end

    hold off;
    ylim([0.9, 1.2].*minmax(abs(zw'))); grid on;
    xlabel('Frequency, Hz');
    
    subplot(3,1,3)
    
    idf = zeros(size(w)); idf(floor((length(w)+1)/2)) = 1;
    ids = fft(idf);

    phase_delay = -mod(unwrap(angle(zw./abs(zw)./ids))+pi/2, pi)+pi/2;

    plot(fs, phase_delay, '.-', 'LineWidth', 1.5); xlim([0, specs.getFps()/2])
    hold on
   
    ylim_phase = ylim();
    
    plot(fs,  options.max_delay*2*pi*fs, '--', 'color', 'Black', 'LineWidth', 1)
    plot(fs, -options.max_delay*2*pi*fs, '--', 'color', 'Black', 'LineWidth', 1)
    hold off;
    
    ylim(ylim_phase.*[1,1.5]); grid on;
    legend(["phase delay", "max delay ("+num2str(round(options.max_delay*1000))+"ms)"]); 
    xlabel('Frequency, Hz'); ylabel('Phase, rad')

    saveas(fig_filt, fullfile(options.diagnosticdir, filename_out + "_filter" + ".png"))
    saveas(fig_filt, fullfile(options.diagnosticdir, filename_out + "_filter" + ".fig"))
    %%
%     subplot(1,2,1)
%     imagesc((1:size(ZW,2))*600/118, fs, plt.saturate((abs(ZW) - mean(abs(ZW),2))./mean(abs(ZW),2), 0.01)); ylim([0,specs.getFps()/2]); caxis([-1,1]*max(abs(caxis)))
%     colormap(plt.redblue)
% 
%     subplot(1,2,2)
%     imagesc((1:size(ZW,2))*600/118, fs, -angle(ZW./abs(ZW)./ids)); ylim([0,specs.getFps()/2]); caxis([-1,1]*max(abs(caxis)))
%     colormap('jet')
    %%
end
%%