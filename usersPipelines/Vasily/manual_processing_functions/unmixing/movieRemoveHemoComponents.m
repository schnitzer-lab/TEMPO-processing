function fullpath_out = movieRemoveHemoComponents(fullpath_movie, fullpaths_components, varargin)

    [basepath, basefilename, ext, postfix] = filenameSplit(fullpath_movie, '_');

    options = defaultOptions(basepath);
    if(~isempty(varargin))
        options = getOptions(options, varargin);
    end

    if(options.divide) options.postfix = options.postfix + "D";
    else options.postfix = options.postfix + "S"; end
    %%    
    
    if (~isfolder(options.outdir)) mkdir(options.outdir); end
    if (~isfolder(options.illustrdir)) mkdir(options.illustrdir); end 
    if (~isfolder(options.diagnosticdir)) mkdir(options.diagnosticdir); end  

    filename_out = basefilename + postfix + options.postfix;
    fullpath_out = fullfile(options.outdir, filename_out + ext);
    
    if (isfile(fullpath_out))
        if(options.skip)
            disp("movieRemoveHemoComponents: Output file exists. Skipping: " + fullpath_out);
            return;
        else
            warning("movieRemoveHemoComponents: Output file exists. Deleting: " + fullpath_out);
            delete(fullpath_out);
        end     
    end
    %%
    
    disp("movieRemoveHemoComponents: reading movie");
    [M, specs] = rw.h5readMovie(fullpath_movie);
    %%
    
    disp("movieRemoveHemoComponents: removing components");
    Mout = M;
    M_mean = mean(M, 3);
    if(specs.extra_specs.isKey("mean_substracted")) 
        M_mean = specs.extra_specs("mean_substracted");
    end
    
    if(specs.extra_specs.isKey("expBaseline_A"))
        M_mean = specs.extra_specs("expBaseline_A");
    end
    
    for i_c = 1:length(fullpaths_components)
        fullpath_c = fullpaths_components(i_c);
        [Mc, specs_c] = rw.h5readMovie(fullpath_c);

        dframes = specs_c.timeorigin - specs.timeorigin;
        
        validframesM = false(size(Mout,3),1);
        validframesM( (max(dframes,0)+1):(min(dframes+size(Mc,3), size(Mout,3))) ) = true;
        
        
        validframesC = false(size(Mc,3),1);
        validframesC( (max(-dframes,0)+1):(min(-dframes+size(Mout,3), size(Mc,3))) ) = true;

        % there is no way the modulation is 150% - edge artifact due to mc
%         to_nan = double(any(1.5*M_mean < abs(Mc(:,:,validframesC)), 3));
%         to_nan(logical(to_nan)) = NaN; to_nan(~isnan(to_nan)) = 1;
%         if(any(isnan(to_nan), 'all')) warning('modulation above 50% -> nan'); end
%         Mc = Mc.*to_nan;
        
        if(options.divide)
            Mout(:,:,validframesM) = (M_mean + Mout(:,:,validframesM))./(1 + Mc(:,:,validframesC)./M_mean) - M_mean;%(M_mean + Mout(:,:,validframesM))./(1 + Mc(:,:,validframesC)./M_mean) - M_mean;
        else
            Mout(:,:,validframesM) = Mout(:,:,validframesM) - Mc(:,:,validframesC);
        end
        Mout(:,:, ~validframesM) = NaN;
    end
    %%

    disp("movieRemoveHemoComponents: saving");
    keep_frames = squeeze(~all(isnan(Mout), [1,2]));
    start_frame = find(keep_frames, 1, 'first');

    specs_new = specs;
    specs_new.AddToHistory(functionCallStruct(...
        {'fullpath_movie', 'fullpaths_components', 'options'}));
    specs_new.AddFrameDelay(start_frame - 1);

    rw.h5saveMovie(fullpath_out, Mout(:,:,keep_frames), specs_new);
    %%

    disp("movieRemoveHemoComponents: saving plots and videos")
    
    savePlots(M(:,:,keep_frames), Mout(:,:,keep_frames), specs, filename_out, options);
end
%%

% fullpathout = fullfile(basepath, [basefilename + postfix + "_filthemo" + ".h5"]);
% rw.h5saveMovie(fullpathout, M(:,:,keep_frames) - Mnew(:,:,keep_frames), specs_new);
% 
% % %%
% fullpathout = fullfile(basepath, [basefilename + postfix + "_filtnohemorange" + ".h5"]);
% rw.h5saveMovie(fullpathout, M(:,:,keep_frames), specs_new);
%%

function options = defaultOptions(basepath)
    
    options.divide = false;
    
    options.outdir = basepath;
    options.illustrdir = basepath + '\illustrations';
    options.diagnosticdir = basepath + '\diagnostic\movieRemoveHemoComponents\';
    options.postfix = "_nohemo";  

    options.skip = true;
end
%%

function savePlots(M, Mout, specs, filename_out, options)

    fig_time = plt.getFigureByName("movieRemoveHemoComponents: Spatially-averaged traces");
    
    m =  squeeze(mean(M,[1,2],'omitnan'));
    m_out =  squeeze(mean(Mout,[1,2],'omitnan'));
    
    plt.tracesComparison([m, m_out], ...
        'labels',["Input", "Nohemo"] + " (mean)",...
        'fps', specs.getFps(), 'fw', 0.3)    
    
    saveas(fig_time, fullfile(options.diagnosticdir, filename_out + "_meantraces" + ".png"))
    saveas(fig_time, fullfile(options.diagnosticdir, filename_out + "_meantraces" + ".fig"))
end
%%