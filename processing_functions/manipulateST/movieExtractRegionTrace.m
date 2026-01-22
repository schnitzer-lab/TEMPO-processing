function fullpath_out_all = movieExtractRegionTrace(fullpath_movie, region_ids, varargin)
    
    [basepath, filename, ext, basefilename, channel, postfix] = ...
        filenameParts(fullpath_movie);

    options = defaultOptions(basepath);
    if(~isempty(varargin))
        options = getOptions(options, varargin);
    end
    %%

    if(~iscell(region_ids)), region_ids = num2cell(region_ids); end
    %%
    
    postfix_new_all = "_"+cellfun(@(s) strjoin(string(s),'+'), region_ids)+"trace";
    filename_out_all = basefilename+channel+postfix+postfix_new_all;
    fullpath_out_all = fullfile(options.outdir, filename_out_all + ext);

    if (all(isfile(fullpath_out_all)))
        if(options.skip)
            disp("movieExtractRegionTrace: All output files exist. Skipping: " + strjoin(fullpath_out_all, ', '))
            return;
        else
            warning("movieExtractRegionTrace: Output files exist. Deleting: " + strjoin(fullpath_out_all, ', '));
            arrayfun(@(p) delete(p) , fullpath_out_all(isfile(fullpath_out_all)));
        end     
    end

    if (~isfolder(options.outdir)), mkdir(options.outdir); end
    if (~isfolder(options.diagnosticdir)), mkdir(options.diagnosticdir); end
    %%
    
    specs = rw.h5readMovieSpecs(fullpath_movie);
    if(isempty(specs.getAllenOutlines()))
        error("movieExtractRegionTrace: no allen outlines found: " + fullpath_movie)
    end
    if(isempty(specs.getMask()))
        warning("movieExtractRegionTrace: no mask found: " + fullpath_movie)
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
    
    movie2d = std(M,[],3);
    movie2d = plt.saturate(movie2d, 0.01);
    %%
    
    for i_r = 1:length(region_ids)
    %% 
    
        region_id = region_ids{i_r};
        postfix_new = postfix_new_all(i_r);
        filename_out = filename_out_all(i_r);
        fullpath_out = fullpath_out_all(i_r);
        if(isfile(fullpath_out) && options.skip), continue; end       
    %%

        disp("movieExtractRegionTrace: extracting trace " + postfix_new);

        if(isstring(region_id) || ischar(region_id))
            region_id = options.regions_map(region_id);
        end    
        %%
    
        fig_roi = plt.getFigureByName("movieExtractRegionTrace: selected roi");
        
        contours= cell(length(region_id),1);
        for i_c = 1:length(region_id)
            contours{i_c} = specs.getAllenOutlines(region_id(i_c));
        end
        if(isempty(contours{1}))
            error("movieExtractRegionTrace: no region " + strjoin(string(region_id),"+") + " found")
        end
        
        [m_reg, mask_reg] = ...
           movieRegion2Trace(M, contours, 'switchxy', false, 'plot', true, 'm2d', movie2d);
        mask_full = (~any(isnan(M), 3)) & mask_reg;        
        %%
        
        if(options.plot)
            disp("movieExtractRegionTrace: plotting")
            
            fig_traces = plt.getFigureByName("movieExtractRegionTrace: mean traces");
            plt.tracesComparison([m,m_reg], 'fps', specs.getFps(), 'fw', 0.25,...
                'labels', ["initial", "region"], 'spacebysd', 3);
            drawnow;
        end
        %%
        
        disp("movieExtractRegionTrace: saving")
        
        specs_out = copy(specs);
        specs_out.AddToHistory(functionCallStruct({'fullpath_movie','region_ids','options'}));
        specs_out.AddBinning(sqrt(sum(mask_full, 'all')));
        remove(specs_out.extra_specs, {'mask'});
        remove(specs_out.extra_specs, {'allenMapEdgeOutline'});
        remove(specs_out.extra_specs, {'allenTransform'});
    
        if(specs.extra_specs.isKey("F0"))
            A = specs.extra_specs("F0");
            specs_out.extra_specs("F0") =  mean(A(mask_full), 'all');
        elseif(specs.extra_specs.isKey("expBaseline_A"))
            A = specs.extra_specs("expBaseline_A");
            specs_out.extra_specs("expBaseline_A") =  mean(A(mask_full), 'all');
        elseif(specs.extra_specs.isKey("expBaseline_end"))
            A = specs.extra_specs("expBaseline_end");
            specs_out.extra_specs("expBaseline_end") =  mean(A(mask_full), 'all');
        elseif(specs.extra_specs.isKey("mean_substracted")) 
            A = specs.extra_specs("mean_substracted");
            specs_out.extra_specs("mean_substracted") =  mean(A(mask_full), 'all');
        end
        %%
        
        rw.h5saveMovie(fullpath_out, reshape(m_reg, [1,1,length(m_reg)]), specs_out);
        %%
        
        saveas(fig_roi, fullfile(options.diagnosticdir, filename_out + "_masking.png"))
        saveas(fig_roi, fullfile(options.diagnosticdir, filename_out + "_masking.fig"))
        if(options.plot)
            saveas(fig_traces, fullfile(options.diagnosticdir, filename_out + "_traces.png"))
            saveas(fig_traces, fullfile(options.diagnosticdir, filename_out + "_traces.fig"))
        end
        %%
    end
end
%%

function options = defaultOptions(basepath)
    
    options.diagnosticdir = basepath + "\diagnostic\extractRegionTrace\";
    options.outdir = basepath;
    
    options.plot = true;
    options.skip = true;
    
    % see allenmap_numbering.PNG. -r for right hemesphere, -l for left, -b
    % for bilateral. Names follow https://connectivity.brain-map.org/3d-viewer
    options.regions_map = containers.Map(...
        ["MO-r", "SS-r", "AUD-r", "VIS-r", "ACA-r", "RSP-r", "PTL-p-r",  ...
         "MOp-r", "MOs-r", ...
         "M1-r", "M2-r",...
         "SSp-r", "SSs-r", ...
         "SSp-n-r", "SSp-bfd-r", "SSp-ll-r", "SSP-m-r", "SSp-ul-r", "SSP-tl-r", "SSP-un-r", ...
         "VISal-r", "VISam-r", "VISI-r", "VISp-r", "VISpl-r", "VISpm-r", "VISli-r", "Vispor-r", ...
         "RSP-alg-r", "RSPd-r", "RSPv-r", ...
         "V1-r", ...
         "V1-l", "RSP-l",  "RSP-b", ...
         "DEC"... % cerebellum CB-CBX-VERM-DEC
         ],...
        {[4,6], 8:2:22, 24:2:30, 32:2:46, 60, [50,64,66], [54,56],...
         4, 6, ...
         4, 6,...
         8:20, 22, ...
         8, 10, 12, 14, 16, 18, 20, ...
         32, 34, 36, 38, 40, 42, 44, 46, ...
         50, 64, 66, ...
         38, ...
         37, [49,65,67], [49,50,64:67], ...
         72});
end
%%
