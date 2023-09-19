function fullpath_out = movieExtractRegionTrace(fullpath_movie, regions, varargin)
    
    [basepath, filename, ext, basefilename, channel, postfix] = ...
        filenameParts(fullpath_movie);

    options = defaultOptions(basepath);
    if(~isempty(varargin))
        options = getOptions(options, varargin);
    end

    postfix_new = "_"+strjoin(string(regions),'+')+"trace";
    %%
    
    if (~isfolder(options.outdir)) mkdir(options.outdir); end
    if (~isfolder(options.diagnosticdir)) mkdir(options.diagnosticdir); end

    filename_out = basefilename+channel+postfix+postfix_new;
    fullpath_out = fullfile(options.outdir, filename_out + ext);
    
    if (isfile(fullpath_out))
        if(options.skip)
            disp("movieExtractRegionTrace: Output file exists. Skipping: " + fullpath_out)
            return;
        else
            warning("movieExtractRegionTrace: Output file exists. Deleting: " + fullpath_out);
            delete(fullpath_out);
        end     
    end
    %%
    
    disp("movieExtractRegionTrace: reading movie")
    [M, specs] = rw.h5readMovie(fullpath_movie);
    m = squeeze(mean(M,[1,2], "omitnan"));
    %%

    if(~isempty(specs.getMask()))
        mask = double(specs.getMask(size(M,[1,2])));
        mask(~(mask)) = nan;
        M = M.*repmat(mask, [1,1,size(M,3)]);
    end
    %%

    if(isstring(regions) || ischar(regions))
        regions = options.regions_map(regions);
    end

    %%

    fig_roi = plt.getFigureByName("movieExtractRegionTrace: selected roi");
    
    contours= cell(length(regions),1);
    for i_c = 1:length(regions)
        contours{i_c} = specs.getAllenOutlines(regions(i_c));
    end
    
    [m_reg, mask_reg] = ...
       movieRegion2Trace(M, contours, 'switchxy', false, 'plot', true);
    mask_full = (~any(isnan(M), 3)) & mask_reg;
    %%
    
    fig_traces = plt.getFigureByName("movieExtractRegionTrace: mean traces");
    plt.tracesComparison([m,m_reg], 'fps', specs.getFps(), 'fw', 0.25,...
        'labels', ["initial", "region"], 'spacebysd', 3);
    %%
    
    disp("movieExtractRegionTrace: saving")
    
    specs_out = copy(specs);
    specs_out.AddToHistory(functionCallStruct({'fullpath_movie','regions','options'}));
    specs_out.AddBinning(sqrt(sum(mask_full, 'all')));

    if(specs.extra_specs.isKey("F0"))
        A = specs.extra_specs("F0");
        specs_out.extra_specs("F0") =  mean(A(mask_full), 'all');
    elseif(specs.extra_specs.isKey("expBaseline_A"))
        A = specs.extra_specs("expBaseline_A");
        specs_out.extra_specs("expBaseline_A") =  mean(A(mask_full), 'all');
    elseif(specs.extra_specs.isKey("mean_substracted")) 
        A = specs.extra_specs("mean_substracted");
        specs_out.extra_specs("mean_substracted") =  mean(A(mask_full), 'all');
    end
    %%
    
    rw.h5saveMovie(fullpath_out, reshape(m_reg, [1,1,length(m_reg)]), specs_out);
    %%
    
    saveas(fig_roi, fullfile(options.diagnosticdir, filename_out + "_masking.png"))
    saveas(fig_roi, fullfile(options.diagnosticdir, filename_out + "_masking.fig"))
    saveas(fig_traces, fullfile(options.diagnosticdir, filename_out + "_traces.png"))
    saveas(fig_traces, fullfile(options.diagnosticdir, filename_out + "_traces.fig"))
end
%%

function options = defaultOptions(basepath)
    
    options.diagnosticdir = basepath + "\diagnostic\extractRegionTrace\";
    options.outdir = basepath;
    options.skip = true;

    options.regions_map = containers.Map(...
        ["M1", "SSp-bfd", "SSp-ll", "V1", "RSP"], ...
        [4,10, 12,38,51]);
end
%%
