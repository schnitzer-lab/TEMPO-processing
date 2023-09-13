function [fullpath_out, fullpathWxy_out, fullpathW0_out]  = ...
    movieEstimateHemoGFilt(fullpath_g, fullpath_r, varargin)
    
%     [basepath, basefilename, ext, postfix] = filenameSplit(fullpath_r, '_');
    [basepath_r, filename_r, ext, ~, ch_r, ~] = filenameParts(fullpath_r);
    [~, ~, ~, ~, ch_g, ~] = filenameParts(fullpath_g);

    options = defaultOptions(basepath_r);
    if(~isempty(varargin))
        options = getOptions(options, varargin);
    end
   
    postfix_new = "_hemoFilt"+"To"+ch_g + ...
        "dt"+string(round(options.dt,1)) + "av"+num2str(options.average_mm)+ ...
        "ma" + string(options.max_amp_rel) + "md" + string(round(options.max_delay*1e3))+ ...
        "e"+num2str(options.eps);
    %%
    
    if (~isfolder(options.outdir)) mkdir(options.outdir); end
    if (~isfolder(options.illustrdir)) mkdir(options.illustrdir); end 
    if (~isfolder(options.diagnosticdir)) mkdir(options.diagnosticdir); end  

    filename_out = filename_r + postfix_new;
    fullpath_out = fullfile(options.outdir, filename_out + ext);
    fullpathWxy_out = fullfile(options.diagnosticdir, filename_out + "_Wxy" + ext);
    fullpathW0_out = fullfile(options.diagnosticdir, filename_out + "_W0" + ext);
        
    if (isfile(fullpath_out))
        if(options.skip)
            disp("movieEstimateHemoGFilt: Output file exists. Skipping:" + fullpath_out);
            return;
        else
            warning("movieEstimateHemoGFilt: Output file exists. Deleting:" + fullpath_out);
            delete(fullpath_out);
            delete(fullpathWxy_out);
            delete(fullpathW0_out);
        end     
    end
    
    if (isfile(fullpathWxy_out) && ~options.save_filtered)
        if(options.skip)
            disp("movieEstimateHemoGFilt: Output file exists. Skipping:" + fullpathWxy_out);
            return;
        else
            warning("movieEstimateHemoGFilt: Output file exists. Deleting:" + fullpathWxy_out);
            delete(fullpathWxy_out);
            delete(fullpathW0_out);
        end     
    end
    %%
    
    disp("movieEstimateHemoGFilt: loading movies")
    
    specs_r = rw.h5readMovieSpecs(fullpath_r);
    sz = rw.h5getDatasetSize(fullpath_g, '/mov');
    % To avoid extra data in the ram, movies are loaded from hard drive
    % when passed to processing functions 

    %%
    
    if(isempty(options.naverage))
        options.naverage = round(options.average_mm/specs_r.getPixSize()/2)*2+1;
    end

    dn = round(specs_r.getFps()*options.dt);
    dn_overlap = round(dn*(1-options.overlap));

    mg = rw.h5getMeanTrace(fullpath_g); %squeeze(mean(Mg,[1,2],'omitnan'));
    mr = rw.h5getMeanTrace(fullpath_r); %squeeze(mean(Mr,[1,2],'omitnan'));
    
    if(isempty(options.fref))
        % find firs hemodynamic peak
        z = pmtm(mr, 0.5*length(mr)/specs_r.getFps()/2); 
        [pks,locs,w,p] = findpeaks(log(z), 2*length(z)/specs_r.getFps(),...
            'MinPeakWidth', 0.3, 'MinPeakProminence', 1.25, 'SortStr', 'descend','Annotate','extents');
        pks_use = (locs>1.5 & locs<20);% always above 1.5Hz & below 20Hz
        locs = locs(pks_use); pks = pks(pks_use); w = w(pks_use); p = p(pks_use); 
        options.fref = locs(1);
    end

   	Mr_filt0 = 0;
    if( options.naverage > 1 )
        disp("movieEstimateHemoGFilt: estimating filter for averaged R trace")
%        
        if(all (sz < options.naverage))
            Mr_in = reshape(repelem(mr, prod(sz(1:2))), sz);
        else
            Mr_in = rw.h5readMovie(fullpath_r); 
            
            % NaNs on the edges due to registration. Sort of the best thing to do - 
            % nan-tolerant smoothing (smooth2a/mm.movieSmooth) takes forever, 
            % imputing (imputeNaNS) takes forever and not sure, if results are great
            Mr_in(isnan(Mr_in)) = 0; 
            Mr_in = smooth3(Mr_in, 'box', [options.naverage, options.naverage,1]);
        end
        
        W0 = estimateFilters( rw.h5readMovie(fullpath_g),  Mr_in, ...
            dn, dn_overlap,  'eps', options.eps, ...
            'fref', options.fref/specs_r.getFps(), 'max_amp_rel',  options.max_amp_rel, ...
            'flim_max', options.flim_max/specs_r.getFps(), ...
            'max_phase', options.max_phase, 'max_delay', options.max_delay*specs_r.getFps());

        Mr_filt0 = applyFilters(Mr_in, W0);
        clear('Mr_in');
    end
    %%

    disp("movieEstimateHemoGFilt: estimating filter for each pixel")

    Wxy = estimateFilters(...
        rw.h5readMovie(fullpath_g) - Mr_filt0, rw.h5readMovie(fullpath_r), ...
        dn, dn_overlap,  'eps', options.eps, ...
        'fref', options.fref/specs_r.getFps(), 'max_amp_rel',  options.max_amp_rel, ...
        'flim_max', options.flim_max/specs_r.getFps(), ...
        'max_phase', options.max_phase, 'max_delay', options.max_delay*specs_r.getFps());   

    Mr_filt = applyFilters(rw.h5readMovie(fullpath_r), Wxy) + Mr_filt0;
    %%
    
    disp("movieEstimateHemoGFilt: saving")
    specs_out = copy(specs_r);
    specs_out.AddToHistory(functionCallStruct({'fullpath_g', 'fullpath_r', 'options'}));

    if(options.save_filtered)
        rw.h5saveMovie(fullpath_out, Mr_filt, specs_r);
    else
        fullpath_out = [];
    end
        
    if (isfile(fullpathWxy_out)) delete(fullpathWxy_out); end
    rw.h5saveMovie(fullpathWxy_out, Wxy, specs_out);

    if( options.naverage > 1 ) 
        if (isfile(fullpathW0_out)) delete(fullpathW0_out); end
        rw.h5saveMovie(fullpathW0_out, W0, specs_out);
    else
        fullpathW0_out = [];
    end   
    %%
    
    disp("movieEstimateHemoGFilt: saving plots and videos")
    
    if( options.naverage > 1 ) Wplot = W0; else Wplot = Wxy; end
    
    savePlots(rw.h5readMovie(fullpath_g), rw.h5readMovie(fullpath_r), ...
        Mr_filt, Wplot, specs_r, filename_out, options);
end
%%

function options = defaultOptions(basepath)
    
    options.dt = 2; % (s) time window for single filter estimation
    options.overlap = 0.75; %(rel) time windows overlap 
    
    options.outdir = basepath;
    options.diagnosticdir = basepath + "\diagnostic\hemoFilt\";
    options.illustrdir = basepath + "\illustrations\";
    
    options.eps = 1e-8; % regularizer weight

    options.fref = [];
    options.max_amp_rel = 1.2;
    options.flim_max = 20; %Hz

    options.max_phase = pi;
    options.max_delay = Inf;
    
    options.naverage = [];
    options.average_mm = 1;

    options.save_filtered = true;
    
    options.skip = true;
end
%%

    
%     X = reshape(Wxy, [prod(size(Wxy0, [1,2])), size(Wxy,3)]);
%     X(isnan(X)) = 0;
%     mu = mean(X, 1);
% 
%     [eigenvectors, scores, latent] = pca(X);
% 
%     nComp = 7;
%     Xhat = scores(:,1:nComp) * eigenvectors(:,1:nComp)';
%     Xhat = bsxfun(@plus, Xhat, mu);
% 
%     Wpc = reshape(Xhat, size(Wxy));
%%

function savePlots(Mg, Mr, Mr_filt, Wxy, specs, filename_out, options)
    
    fig_time = plt.getFigureByName("movieEstimateHemoGFilt: Spatially-averaged traces");
    
    Mg(isnan(Mr_filt)) = NaN;
    Mr(isnan(Mr_filt)) = NaN;
    
    mg =  squeeze(mean(Mg,[1,2],'omitnan'));
    mr =  squeeze(mean(Mr,[1,2],'omitnan'));
    mr_filt = squeeze(mean(Mr_filt,[1,2],'omitnan'));
    mg_nohemo  = squeeze(mean(Mg-Mr_filt, [1,2],'omitnan'));
    
    plt.tracesComparison([mg, mr, mr_filt, mg_nohemo, mg-mr*(mr\mg)], ...
        'labels',["ch1", "ch2", "hemo_toch1", "umx filter", "umx regression"] + " (mean)",...
        'fps', specs.getFps(), 'fw', 0.5, ...
        'nomean', false, 'spacebysd', 2.5);
    
    saveas(fig_time, fullfile(options.diagnosticdir, filename_out + "_meantraces" + ".png"))
    saveas(fig_time, fullfile(options.diagnosticdir, filename_out + "_meantraces" + ".fig"))
    
    %%
    
    fig_filt= plt.getFigureByName("movieEstimateHemoGFilt: Spatially-averaged filter");
    
    w =  squeeze(mean(Wxy, [1,2], 'omitnan'));

    zw = fft(w);
    fs = linspace(0,specs.getFps, length(zw));
    [~,ind_f0] = min(abs(fs-options.fref));

    v0 = zeros(size(w)); v0(length(v0)/2+1) = abs(zw(ind_f0));
    v1 = zeros(size(w)); v1(length(v1)/2+1) = options.max_amp_rel*abs(zw(ind_f0));

    plt.tracesComparison([w/abs(zw(ind_f0)), v0/abs(zw(ind_f0)), v1/abs(zw(ind_f0))], ...
        'labels', ["Filter (rel to reg @fref)", "reg @fref", "amp_limit ("+string(options.max_amp_rel)+")"],...
        'fps', specs.getFps(), 'fw', .2, 't0', -(length(w))/2/specs.getFps())   
    ax1 = subplot(2,1,1); delete(ax1.Children(1));delete(ax1.Children(1));
    subplot(2,1,2)
    hold on;
    xline(options.fref, '--');
    hold off;

    saveas(fig_filt, fullfile(options.diagnosticdir, filename_out + "_filter" + ".png"))
    saveas(fig_filt, fullfile(options.diagnosticdir, filename_out + "_filter" + ".fig"))
end
%%