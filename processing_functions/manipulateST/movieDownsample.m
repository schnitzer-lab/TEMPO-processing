function fullpath_out = movieDownsample(fullpath_movie, nt, ns, varargin)
    
    [basepath, filename, ~] = fileparts(fullpath_movie);
    
    options = defaultOptions(basepath);
    if(~isempty(varargin))
        options = getOptions(options, varargin);
    end

    paramssummary = [num2str(ns), 's', num2str(nt), 't'];
    postfix_new = "_down" + paramssummary;

    %%

    %%

    if (~isfolder(options.outdir)), mkdir(options.outdir); end
    if (~isfolder(options.diagnosticdir)), mkdir(options.diagnosticdir); end

    filename_out = filename + postfix_new;
    fullpath_out = fullfile(options.outdir , filename_out + ".h5");
 
    if (isfile(fullpath_out))
        if(options.skip)
            displog("movieDownsample: Output file exists. Skipping: " + fullpath_out)
            return;
        else
            warning("movieDownsample: Output file exists. Deleting: " + fullpath_out);
            delete(fullpath_out);
        end     
    end
    %%
    
    displog("movieDownsample: reading movie");
    [Mraw, specs] = rw.h5readMovie(fullpath_movie);
    %%
    
    if(~isempty(options.type))
       Mraw = cast(Mraw, options.type);
    end
    %%

    displog("movieDownsample: downsampling");
    M_tdownsampled = mm.DownsampleTime(Mraw, nt);
    M_xytdownsampled = mm.DownsampleSpace(M_tdownsampled, ns);  %NUM_CORES
    %%

    displog("movieDownsample: saving");
    specs_out = copy(specs);
    specs_out.AddBinning(ns);
    specs_out.AddBinningTime(nt);

    specs_out.AddToHistory(functionCallStruct({'fullpath_movie','nt','ns','options'}));
    %%
    if(specs.extra_specs.isKey("F0"))
        specs_out.extra_specs("F0") =  mm.DownsampleSpace(specs.extra_specs("F0"), ns);
    elseif(specs.extra_specs.isKey("expBaseline_A"))
        specs_out.extra_specs("expBaseline_A") =  mm.DownsampleSpace(specs.extra_specs("expBaseline_A"), ns);
    elseif(specs.extra_specs.isKey("mean_substracted")) 
        specs_out.extra_specs("mean_substracted") =  mm.DownsampleSpace(specs.extra_specs("mean_substracted"), ns);
    end
    %%
    rw.h5saveMovie(fullpath_out, M_xytdownsampled, specs_out);

    %%
    
    m = squeeze(mean(Mraw, [1,2], 'omitnan'));
    mdown = squeeze(mean(M_xytdownsampled, [1,2], 'omitnan'));
    
    fig_mean = plt.getFigureByName("Downsampling - mean traces comparison");

    [axplot, axspec] = plt.tracesComparison(m, ...
        'fps', specs.getFps(), 'fw', 0.2, 'f0', specs.getFrequencyRange(1));
    hold(axplot, 'on'); hold(axspec, 'on');
    xls = xlim(axspec); yls = ylim(axspec);
    
    plt.tracesComparison(mdown, ...
        'fps', specs_out.getFps(), 'fw', 0.2, 'f0', specs.getFrequencyRange(1), ...
        't0', 0.5/specs.getFps(), ...
        'labels', ["original", "downsampled"], ...
        'axplot', axplot, 'axspec', axspec);
    hold(axplot, 'off'); hold(axspec, 'off');
    xlim(xls); ylim(yls);
    %%

    pix = round(size(Mraw, [1,2]).*[1/3,2/3]);
    m = squeeze(Mraw(pix(1), pix(2),:));

    pixdown = round(size(M_xytdownsampled, [1,2]).*[1/3,2/3]);
    mdown = squeeze(M_xytdownsampled(pixdown(1), pixdown(2),:));
    
    fig_pix = plt.getFigureByName("Downsampling - single pix traces comparison");

    [axplot, axspec] = plt.tracesComparison(m, ...
        'fps', specs.getFps(), 'fw', 0.2, 'f0', specs.getFrequencyRange(1));
    hold(axplot, 'on'); hold(axspec, 'on');
    xls = xlim(axspec); yls = ylim(axspec);
    
    plt.tracesComparison(mdown, ...
        'fps', specs_out.getFps(), 'fw', 0.2, 'f0', specs.getFrequencyRange(1), ...
        't0', 0.5/specs.getFps(), ...
        'labels', ["original", "downsampled"], ...
        'axplot', axplot, 'axspec', axspec);
    hold(axplot, 'off'); hold(axspec, 'off');
    xlim(xls); 
    % ylim(yls);
    %%

    saveas(fig_mean, fullfile(options.diagnosticdir, filename_out  + '_traces.png') );
    saveas(fig_mean, fullfile(options.diagnosticdir, filename_out  + '_traces.fig') );
    saveas(fig_pix, fullfile(options.diagnosticdir, filename_out  + '_tracespix.png') );
    saveas(fig_pix, fullfile(options.diagnosticdir, filename_out  + '_tracespix.fig') );

    imwrite(mat2gray(mean(Mraw,3)), fullfile(options.diagnosticdir, filename_out + "_mean_in.bmp"));
    imwrite(mat2gray(mean(M_xytdownsampled,3)), fullfile(options.diagnosticdir, filename_out + "_mean_out.bmp"));
end

function options = defaultOptions(basepath)
    
    options.diagnosticdir = basepath + "\diagnostic\downsample\";
    options.outdir = basepath;
    options.type = [];
    options.skip = true;
end


