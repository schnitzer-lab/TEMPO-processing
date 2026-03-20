function [fullpath_out, fullpathWxy_out, fullpathWsm_out]  = ...
    movieEstimateHemoGFilt(fullpath_sig, fullpath_ref, varargin)
    
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
    
    displog("reading movies")
        
    [Mg, ~] = rw.h5readMovie(fullpath_sig);
    [Mr, specs_r] = rw.h5readMovie(fullpath_ref);

    % on the edges after registration/motion correction + filtering, there 
    % are some pixels with hf noise ~= 0, which cases instability. Setting 
    % all the edge pixels (near NaN's and at the image boundaty) to NaNs
    mask_nan = ones(size(Mr, [1,2])); mask_nan(isnan(mean(Mr,3))) = NaN;
    mask_nan = conv2(mask_nan, ones(3,3), 'same'); mask_nan(~isnan(mask_nan)) = 1;
    mask_nan(1,:) = NaN; mask_nan(end,:) = NaN; 
    mask_nan(:,1) = NaN; mask_nan(:,end) = NaN;
    Mr = Mr .* mask_nan;

    sz = size(Mr);
    mr = squeeze(mean(Mr, [1,2], 'omitnan'));%rw.h5getMeanTrace(fullpath_ref);
%     mg = squeeze(mean(Mg, [1,2], 'omitnan'));%rw.h5getMeanTrace(fullpath_sig);
    %%
    
    wn = round(specs_r.getFps()*options.dt);
    if(mod(wn,2) == 0), wn = wn+1; end % unnecessary, but nice for plotting
    no = round(wn*options.overlap);
    
    if(isempty(options.fref))
        % find first hemodynamic peak
        [~,locs,~, ~, ~] = findpeaksspectral(mr, options.fref_resolution, ...
            specs_r.getFps(),  options.fref_lims, ...
            'MinPeakWidth', options.fref_minpeakwidth, ...
            'MinPeakProminence', options.fref_minpeakprominance, 'SortStr', 'descend');
        options.fref = locs(1);
    end

    options_estimate_sm = struct('npixatonece', options.npixatonce, ...
        'usereg', options.usereg, 'fref', options.fref/specs_r.getFps());
    options_estimate_xy = struct('npixatonece', options.npixatonce, ...
        'usereg', options.usereg, 'fref', []);
    options_limit = struct(...
        'fref', options.fref/specs_r.getFps(), 'max_amp_rel', options.max_amp_rel, ...
        'flim_max', options.flim_max/specs_r.getFps(), ...
        'max_phase', options.max_phase, 'max_delay', options.max_delay*specs_r.getFps());
    
    if(isempty(options.naverage))
        options.naverage = round(options.average_mm/specs_r.getPixSize()/2)*2+1;
    end
    %%

    displog("performing spatial averaging")
    % local correction in case of ref spatial averaging
    Mr_sm = 0;
    if( options.naverage > 1 )
        if(all(sz(1:2) <= options.naverage))
            Mr_sm = reshape(repelem(mr, prod(sz(1:2))), sz);
            % Mg_sm = reshape(repelem(mg, prod(sz(1:2))), sz);
        else
            Mr_sm = rw.h5readMovie(fullpath_ref); 
     % 
            % NaNs on the ref edges due to registration. Imputing (imputeNaNS) or 
            % nan-tolerant smoothing (smooth2a/mm.movieSmooth) takes forever
            Mr_sm(isnan(Mr_sm)) = 0; 
            Mr_sm = smooth3(Mr_sm, 'box', [options.naverage, options.naverage,1]);
        end
    end
    %%
    
    Mr_xy_filt = zeros(size(Mr), class(Mr)); Mr_sm_filt = zeros(size(Mr), class(Mr));
    Wxy = zeros([size(Mg,[1,2]), wn], class(Mg)); 
    Wsm = zeros([size(Mg,[1,2]), wn], class(Mg));    

    nrowsatonce = floor(options.npixatonce/size(Mg,2));

    for iter = 1:options.niter 
        %%        
         
        for r1 = 1:nrowsatonce:size(Mg,1)
            r2 = min(r1 + nrowsatonce - 1, size(Mg,1));
        %%
        
            displog("estimating filter for smoothed ref traces"...
                + sprintf(" (%d:%d/%d, %d/%d)",r1,r2,size(Mg,1),iter,options.niter)) 
   
            Wsm(r1:r2,:,:) = estimateFilters(...
                Mg(r1:r2,:,:)-Mr_xy_filt(r1:r2,:,:), Mr_sm(r1:r2,:,:), ...
                wn, no, options_estimate_sm);  
            Wsm(r1:r2,:,:) = limitFiltersTimeResolved(Wsm(r1:r2,:,:), options_limit);       
            Mr_sm_filt(r1:r2,:,:) = applyFilters(Mr_sm(r1:r2,:,:), Wsm(r1:r2,:,:));  
      
            displog("estimating filter for single-pixel traces"...
                + sprintf(" (%d:%d/%d, %d/%d)",r1,r2,size(Mg,1),iter,options.niter))
    
            Wxy(r1:r2,:,:) = estimateFilters(...
                Mg(r1:r2,:,:)-Mr_sm_filt(r1:r2,:,:), Mr(r1:r2,:,:), ...
                wn, no, options_estimate_xy);
            Wxy(r1:r2,:,:) = limitFiltersTimeResolved(Wxy(r1:r2,:,:), options_limit);
            Mr_xy_filt(r1:r2,:,:) = applyFilters(Mr(r1:r2,:,:), Wxy(r1:r2,:,:));   
        end
        % do not propagate NaN's from red if possible
        Mr_xy_filt(isnan(Mr_xy_filt) & ~isnan(Mr_sm_filt)) = 0;        
    end
    %%

    Mr_filt = (Mr_sm_filt + Mr_xy_filt);
    clear('Mr_sm'); clear('Mr_sm_filt'); clear('Mr_xy_filt');
    %%
    
    displog("saving")

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
    
    displog("generating and saving plots")
            
    savePlots(Mg, Mr, Mr_filt, Wsm, Wxy, specs_r, filename_out, options);
end
%%

function options = defaultOptions(basepath)

    options.dt = 2; % s, time window for single filter estimation
    options.overlap = 0.75; % time windows relative overlap 

    options.naverage = []; % number of points for reference ch spatial averaging 
    options.average_mm = Inf; % mm, scale for reference ch spatial averaging 
    options.niter = 3; % number of times to repeat the estimation
    options.usereg = false;  % use regularized version of the filter estimation
    options.npixatonce = Inf;  % number of spatial pixel to process simultaneously
    
    options.fref = []; % Hz,  main hemodynamic peak frequency
    options.fref_lims = [1.5, 20]; %Hz, limits for finding main hemodynamic peak frequency
    options.fref_resolution = 0.4; % for finding main hemodynamic peak frequency 
    options.fref_minpeakwidth = 0.3; % for finding main hemodynamic peak frequency
    options.fref_minpeakprominance = 1.5; % for finding main hemodynamic peak frequency

    options.max_amp_rel = 1.1; % max filter amplitude (across freq) rel to its amplitude @ fref 
    options.max_phase = pi;  % max filter phase (across freq)
    options.max_delay = Inf; % s, max filter delay (across freq)
    options.flim_max = 20; % Hz, maximum frequency below wich the filter limits above apply

    options.diagnosticdir = fullfile(basepath, 'diagnostic', 'hemoFilt');
    options.illustrdir = fullfile(basepath, 'illustrations');
 
    options.outdir = basepath;
    options.postfix_new = "_hemoFilt";
    options.skip = true;
end
%%

function [fullpath_out, fullpathWxy_out, fullpathW0_out, do_skip] = ...
    setupOutput(fullpath_sig, fullpath_ref, options)

    [~, filename_ref, ext, ~, ~, ~] = filenameParts(fullpath_ref);
    [~, ~, ~, ~, ch_sig, ~] = filenameParts(fullpath_sig);
   
    postfix_new = options.postfix_new + "to"+ch_sig+...
        "dt"+string(round(options.dt,1)) + "nav"+num2str(options.naverage) + ...
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
            displog("Output file exists. Skipping:" + fullpath_out);
            do_skip = true;
            return;
        else
            warning("movieEstimateHemoGFilt: Output file exists. Deleting:" + fullpath_out);
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

%     w =  squeeze(mean(Wsm(pix_loc(1),pix_loc(2),:,:), [1,2,4], 'omitnan'));
%     zw = fft(w);
%     fs = linspace(0,specs.getFps, length(zw));
%     [~,ind_f0] = min(abs(fs-options.fref));
 
    mg =  squeeze(Mg(pix_loc(1),pix_loc(2),:));
    mr =  squeeze(Mr(pix_loc(1),pix_loc(2),:));
    mr_filt = squeeze(Mr_filt(pix_loc(1),pix_loc(2),:));
    mg_nohemo  = squeeze(Mg(pix_loc(1),pix_loc(2),:)-Mr_filt(pix_loc(1),pix_loc(2),:));
    a = (mr\mg); % abs(zw(ind_f0)); % 
    
    fig_time_pix = plt.getFigureByName("movieEstimateHemoGFilt: single pix");

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
      
    fig_time = plt.getFigureByName("movieEstimateHemoGFilt: Spatially-averaged traces");
 
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
    
    options_plotfilter = copyStruct(options, {'fref', 'max_amp_rel', 'flim_max', 'max_delay'});
    options_plotfilter.frange = specs.getFrequencyRange();
    
    fig_filt= plt.getFigureByName("movieEstimateHemoGFilt: Spatially-averaged filter");
    fig_filt.Position(4) = 630;
    sgtitle('Unmixing filter')    
    
    plotFiter(reshape(Wsm, [], size(Wsm, 3)), ...
        specs.getFps(), options_plotfilter);

    saveas(fig_filt, fullfile(options.diagnosticdir, filename_out + "_filter" + ".png"))
    saveas(fig_filt, fullfile(options.diagnosticdir, filename_out + "_filter" + ".fig"))
    %%

    fig_filt= plt.getFigureByName("movieEstimateHemoGFilt: Spatially-averaged filter (local)");
    fig_filt.Position(4) = 630;
    
    sgtitle('Unmixing filter (local)')
    
    plotFiter(reshape(Wxy, [], size(Wxy, 3)), ...
        specs.getFps(), options_plotfilter);

    saveas(fig_filt, fullfile(options.diagnosticdir, filename_out + "_filterxy" + ".png"))
    saveas(fig_filt, fullfile(options.diagnosticdir, filename_out + "_filterxy" + ".fig"))
end
%%

function plotFiter(Wall, fps, options)
    %%

    ts = ((1:size(Wall,2))-(size(Wall,2)+1)/2)/fps;
    fs = linspace(0, fps, size(Wall,2));
    %%

    w = squeeze(mean(Wall, 1, 'omitnan'))';

    sampled_points = randsample(1:size(Wall,1), min(size(Wall,1), 1000));
    
    Wsampled = Wall(sampled_points, :);
    ZW = transpose(fft(transpose(Wsampled)));
    zw = fft(w);
 
    subplot(3,1,1)
    plot(ts, transpose(Wsampled), ...
        'color', [0.5,0.5,0.9,10/length(sampled_points)]); hold on;
    plot( ts, w, 'LineWidth', 1.5, 'Color', 'blue'); 
    
    legend([repelem("", length(sampled_points)), "time representation"]); 
    
    hold off; grid on;
    xlim([min(ts), max(ts)]); ylim([floor(min(w)/0.25), ceil(max(w)/0.25)]*0.25)
    xlabel('Time, s'); 
    %%

    subplot(3,1,2)

    ZW(:, fs <= options.frange(1)) = NaN;
    zw(fs <= options.frange(1)) = NaN;
    [~,ind_f0] = min(abs(fs-options.fref));

    semilogy(fs, abs(ZW), 'color', ...
        [0.5,0.5,0.9,10/length(sampled_points)]); hold on;
    semilogy(fs, abs(zw), '.-', 'LineWidth', 1.5, 'Color', 'blue');     
    legend([repelem("", length(sampled_points)), "spectral amplitude"], ...
        'Location', 'southeast');

    if(options.max_amp_rel < inf)
        a = max(abs(zw(ind_f0)), median(abs(zw)));
        line([0, options.flim_max], ...
             [1, 1]*options.max_amp_rel*a, ...
            'LineStyle', '--', 'Color', 'black', 'LineWidth', 1);
        scatter(options.fref, abs(zw(ind_f0)), 'o', 'red')

        legend([repelem("", length(sampled_points)), "spectral amplitude", ...
            "limit ("+num2str(options.max_amp_rel)+"*ref)", "reference"]);
    end

    hold off; grid on;
    xlim([0, fps/2]); % ylim([0.9, 1.3].*[min(abs(zw')), max(abs(zw'))]);
    xlabel('Frequency, Hz');

    %%

    subplot(3,1,3)
    
    idf = zeros(size(w)); idf(floor((length(w)+1)/2)) = 1;
    ids = fft(idf);

    pd = -mod(unwrap(angle(zw./abs(zw)./ids))+pi/2, pi)+pi/2;
    PD = -mod(unwrap(angle(ZW./abs(ZW)./transpose(ids)))+pi/2, pi)+pi/2;

    plot(fs, transpose(PD), 'color', [0.5,0.5,0.9,0.01]); hold on
    plot(fs, pd, '.-', 'LineWidth', 1.5, 'color', 'blue');
    
    plot(fs,  options.max_delay*2*pi*fs, '--', 'color', 'Black', 'LineWidth', 1)
    plot(fs, -options.max_delay*2*pi*fs, '--', 'color', 'Black', 'LineWidth', 1)
    
    legend([repelem("", length(sampled_points)), "phase delay", ...
        "max delay ("+num2str(round(options.max_delay*1000))+"ms)"]); 
    
    hold off; grid on;    
    xlim([0, fps/2]); ylim([-1,1]*pi/2); 
    xlabel('Frequency, Hz'); ylabel('Phase, rad')
end

