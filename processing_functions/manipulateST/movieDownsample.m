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
    if (~isfolder(options.processingdir)), mkdir(options.processingdir); end

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
    
    M_tot = squeeze(mean(Mraw(1:min(size(M_xytdownsampled,1)*ns, size(Mraw, 1)),...
                              1:min(size(M_xytdownsampled,2)*ns, size(Mraw, 2)),:), [1,2], 'omitnan'));
    Mdown_tot = repelem(squeeze(mean(M_xytdownsampled, [1,2], 'omitnan')), nt);
    
    fig = plt.getFigureByName("Downsampling - traces comparison");
    plt.tracesComparison([M_tot(1:length(Mdown_tot)), Mdown_tot], 'fps', specs.getFps(),...
        'labels', ["original", "downsampled"])

    saveas(fig, fullfile(options.processingdir, filename_out  + '_traces.png') )
    saveas(fig, fullfile(options.processingdir, filename_out  + '_traces.fig') )

    imwrite(mat2gray(mean(Mraw,3)), fullfile(options.processingdir, filename_out + "_mean_in.bmp"));
    imwrite(mat2gray(mean(M_xytdownsampled,3)), fullfile(options.processingdir, filename_out + "_mean_out.bmp"));
end

function options = defaultOptions(basepath)
    
    options.processingdir = basepath + "\diagnostic\movieDownsampe\";
    options.outdir = basepath;
    options.type = [];
    options.skip = true;
end


