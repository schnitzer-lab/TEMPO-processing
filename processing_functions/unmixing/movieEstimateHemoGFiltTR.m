function [fullpath_out, fullpathWxy_out, fullpathWsm_out]  = ...
    movieEstimateHemoGFiltTR(fullpath_sig, fullpath_ref, varargin)
    
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
    
    disp("movieEstimateHemoGFiltTR: reading movies")
        
    [Mg, ~] = rw.h5readMovie(fullpath_sig);
    [Mr, specs_r] = rw.h5readMovie(fullpath_ref);
    sz = size(Mr);
    
    % on the edges after registration/motion correction + filtering, there are some
    % pixels with hf noise ~= 0, which cases instability
    Mr_std = std(Mr,[], 3); Mr_std_rel = log(Mr_std./median(Mr_std(:), 'omitnan'));
    make_nan = (Mr_std_rel < -4*std(Mr_std_rel(:),[], 'omitnan'));
    mask_nan = nan(size(Mr_std)); mask_nan(make_nan==0) = 1;
    Mr = Mr .* mask_nan;

    mr = squeeze(mean(Mr, [1,2], 'omitnan'));%rw.h5getMeanTrace(fullpath_ref);
    mg = squeeze(mean(Mg, [1,2], 'omitnan'));%rw.h5getMeanTrace(fullpath_sig);
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

    options_estimate_sm = struct('npixatonece', options.npixatonce, ...
        'usereg', options.usereg, 'frefs', frefs/specs_r.getFps());
    options_estimate_xy = struct('npixatonece', options.npixatonce, ...
        'usereg', options.usereg, 'frefs', []);
    options_limit = struct(...
        'fref', frefs/specs_r.getFps(), 'max_amp_rel', options.max_amp_rel, ...
        'flim_max', options.flim_max/specs_r.getFps(), ...
        'max_phase', options.max_phase, 'max_delay', options.max_delay*specs_r.getFps());
    
    if(isempty(options.naverage))
        options.naverage = round(options.average_mm/specs_r.getPixSize()/2)*2+1;
    end
    %%

    disp("movieEstimateHemoGFiltTR: performing spatial averaging")
    % local correction in case of ref spatial averaging
    Mr_sm = 0;
    if( options.naverage > 1 )
        if(all(sz(1:2) <= options.naverage))
            Mr_sm = reshape(repelem(mr, prod(sz(1:2))), sz);
            % Mg_sm = reshape(repelem(mg, prod(sz(1:2))), sz);
        else
            Mr_sm = rw.h5readMovie(fullpath_ref); 
     
            % NaNs on the ref edges due to registration. Imputing (imputeNaNS) or 
            % nan-tolerant smoothing (smooth2a/mm.movieSmooth) takes forever
            Mr_sm(isnan(Mr_sm)) = 0; 
            Mr_sm = smooth3(Mr_sm, 'box', [options.naverage, options.naverage,1]);
        end
    end
    %%
    
    Mr_xy_filt = zeros(size(Mr), class(Mr)); Mr_sm_filt = zeros(size(Mr), class(Mr));
    Wxy = zeros([size(Mg,[1,2]), wn, size(chunks,1)], class(Mg)); 
    Wsm = zeros([size(Mg,[1,2]), wn, size(chunks,1)], class(Mg));   
    
    nrowsatonce = floor(options.npixatonce/size(Mg,2));
  
   for iter = 1:options.niter 
        %%

        for r1 = 1:nrowsatonce:size(Mg,1)
            r2 = min(r1 + nrowsatonce - 1, size(Mg,1));
        %%
        
            disp("movieEstimateHemoGFiltTR: estimating filter for smoothed ref traces"...
                + sprintf(" (%d:%d/%d, %d/%d)",r1,r2,size(Mg,1),iter,options.niter))
    
            Wsm(r1:r2,:,:,:) = estimateFiltersTimeResolved(...
                Mg(r1:r2,:,:)-Mr_xy_filt(r1:r2,:,:),  Mr_sm(r1:r2,:,:), ...
                wn, no, chunks, options_estimate_sm);  
            Wsm(r1:r2,:,:,:) = limitFiltersTimeResolved(Wsm(r1:r2,:,:,:), options_limit);       
            Mr_sm_filt(r1:r2,:,:) = applyFiltersTimeResolved(...
                Mr_sm(r1:r2,:,:), Wsm(r1:r2,:,:,:), chunks, chunks_nooverlap);  
      
            disp("movieEstimateHemoGFiltTR: estimating filter for single-pixel traces"...
                + sprintf(" (%d:%d/%d, %d/%d)",r1,r2,size(Mg,1),iter,options.niter))
    
            Wxy(r1:r2,:,:,:) = estimateFiltersTimeResolved(...
                Mg(r1:r2,:,:)-Mr_sm_filt(r1:r2,:,:), Mr(r1:r2,:,:), ...
                wn, no, chunks, options_estimate_xy); % Mr-Mr_sm?
            Wxy(r1:r2,:,:,:) = limitFiltersTimeResolved(Wxy(r1:r2,:,:,:), options_limit);
            Mr_xy_filt(r1:r2,:,:) = applyFiltersTimeResolved(...
                Mr(r1:r2,:,:), Wxy(r1:r2,:,:,:), chunks, chunks_nooverlap);   
        end
    end
    %%
    
    Mr_filt = (Mr_sm_filt + Mr_xy_filt);
    clear('Mr_sm'); clear('Mr_sm_filt'); clear('Mr_xy_filt');
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
    savePlots(Mg, Mr, Mr_filt, Wsm, Wxy, specs_r, filename_out, options);
end
%%

function options = defaultOptions(basepath)
    
    options.dt = 2; % s, time window for single filter estimation
    options.overlap = 0.6; % time windows relative overlap 
    
    options.dt_slow = 30; % s, timescale of filter evolution

    options.naverage = []; % number of points for reference ch spatial averaging 
    options.average_mm = Inf; % mm, scale for reference ch spatial averaging 
    options.niter = 3; % number of times to repeat the estimation
    options.usereg = false; % use regularized version of the filter estimation 
    options.npixatonce = Inf;  % number of spatial pixel to process simultaneously
    
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

function savePlots(Mg, Mr, Mr_filt, Wsm, Wxy, specs, filename_out, options)
    
    Mg(isnan(Mr_filt)) = NaN;
    Mr(isnan(Mr_filt)) = NaN;

    if(~isempty(specs.getMask()))
        Mg = Mg.*specs.getMaskNaN();
        Mr = Mr.*specs.getMaskNaN();
        Mr_filt = Mr_filt.*specs.getMaskNaN();
        Wsm = Wsm.*specs.getMaskNaN();
        Wxy = Wxy.*specs.getMaskNaN();
    end
    %%

    pix_loc =  round(size(Mr, [1,2])/2);

    w =  squeeze(mean(Wsm(pix_loc(1),pix_loc(2),:,:), [1,2,4], 'omitnan'));
    zw = fft(w);
    fs = linspace(0,specs.getFps, length(zw));
    [~,ind_f0] = min(abs(fs-options.fref));
 
    mg =  squeeze(Mg(pix_loc(1),pix_loc(2),:));
    mr =  squeeze(Mr(pix_loc(1),pix_loc(2),:));
    mr_filt = squeeze(Mr_filt(pix_loc(1),pix_loc(2),:));
    mg_nohemo  = squeeze(Mg(pix_loc(1),pix_loc(2),:)-Mr_filt(pix_loc(1),pix_loc(2),:));
    a = (mr\mg); % abs(zw(ind_f0)); % 
    
    fig_time_pix = plt.getFigureByName("movieEstimateHemoGFiltTR: single pix");

    plt.tracesComparison([mg, mr*a, mr_filt, mg-mr*a, mg_nohemo], ...
        'labels',["ch1", "ch2 (scaled)", "ch2 (filtered)", "umx regression", "umx filter"],...
        'fps', specs.getFps(), 'fw', 0.2, ...
        'nomean', false, 'spacebysd', [0,3,0,3,0], 'f0', specs.getFrequencyRange(1));
    sgtitle(['pixel ' , sprintf('(%d, %d)', pix_loc(1),  pix_loc(2))]);
    
    saveas(fig_time_pix, fullfile(options.diagnosticdir, filename_out + "_pixtraces" + ".png"))
    saveas(fig_time_pix, fullfile(options.diagnosticdir, filename_out + "_pixtraces" + ".fig"))
    %%
        
    w =  squeeze(mean(Wsm, [1,2,4], 'omitnan'));
    
    zw = fft(w);
    fs = linspace(0,specs.getFps, length(zw));
    [~,ind_f0] = min(abs(fs-options.fref));
      
    fig_time = plt.getFigureByName("movieEstimateHemoGFiltTR: Spatially-averaged traces");
 
    mg =  squeeze(mean(Mg,[1,2],'omitnan'));
    mr =  squeeze(mean(Mr,[1,2],'omitnan'));
    mr_filt = squeeze(mean(Mr_filt,[1,2],'omitnan'));
    mg_nohemo  = squeeze(mean(Mg-Mr_filt, [1,2],'omitnan'));
    a = (mr\mg); % abs(zw(ind_f0)); % 

    plt.tracesComparison([mg, mr*a, mr_filt, mg-mr*a, mg_nohemo], ...
        'labels',["ch1", "ch2 (scaled)", "ch2 (filtered)", "umx regression", "umx filter"],...
        'fps', specs.getFps(), 'fw', 0.2, ...
        'nomean', false, 'spacebysd', [0,3,0,3,0], 'f0', specs.getFrequencyRange(1));
    sgtitle('spatially averaged');
    
    saveas(fig_time, fullfile(options.diagnosticdir, filename_out + "_meantraces" + ".png"))
    saveas(fig_time, fullfile(options.diagnosticdir, filename_out + "_meantraces" + ".fig"))
    %%

    W =  squeeze(mean(Wsm, [1,2], 'omitnan'));
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
    xlabel('Time, s'); xlim([min(ts), max(ts)])

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
    ylim([0.9, 1.2].*[min(abs(zw')), max(abs(zw'))]); grid on;
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
        
    W =  squeeze(mean(Wxy, [1,2], 'omitnan'));
    w = mean(W,2);
    ZW = fft(W);
    zw = mean(ZW,2);
    zw(fs < specs.getFrequencyRange(1)) = NaN;

    ts = ((1:length(w))-(length(w)+1)/2)/specs.getFps();

    fig_filt= plt.getFigureByName("movieEstimateHemoGFiltTR: Spatially-averaged filter (local)");
    fig_filt.Position(4) = 630;
    
    sgtitle('Unmixing filter (local)')
    subplot(3,1,1)
    plot( ts, w, 'LineWidth', 1.5);
    legend('time representation'); grid();
    xlabel('Time, s'); xlim([min(ts), max(ts)])

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
    ylim([0.9, 1.2].*[min(abs(zw')), max(abs(zw'))]); grid on;
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

    saveas(fig_filt, fullfile(options.diagnosticdir, filename_out + "_filterxy" + ".png"))
    saveas(fig_filt, fullfile(options.diagnosticdir, filename_out + "_filterxy" + ".fig"))
end
%%