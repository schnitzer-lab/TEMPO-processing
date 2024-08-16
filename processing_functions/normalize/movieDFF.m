function fullpath_out = movieDFF(fullpath_movie, varargin)
    
    [basepath, basefilename, ext, postfix] = filenameSplit(fullpath_movie, '_');

    options = defaultOptions(fullpath_movie);
    if(~isempty(varargin))
        options = getOptions(options, varargin);
    end

    postfix_new = "_dFF";
    %%
    
    if (~isfolder(options.outdir)) mkdir(options.outdir); end
    if (~isfolder(options.diagnosticdir)) mkdir(options.diagnosticdir); end

    filename_out = basefilename + postfix + postfix_new;
    fullpath_out = fullfile(options.outdir, filename_out + ext);
    
    if (isfile(fullpath_out))
        if(options.skip)
            disp("movieDFF: Output file exists. Skipping: " + fullpath_out)
            return;
        else
            warning("movieDFF: Output file exists. Deleting: " + fullpath_out);
            delete(fullpath_out);
        end     
    end
    %%
    
    disp("movieDFF: reading movie")
    
    [Mraw, specs] = rw.h5readMovie(fullpath_movie);%rw.h5readMovie(fullfile(basepath, basefilename + "_reg_moco_cropMovie_masked_decross" + ".h5"));
    %%
    
    disp("movieDFF: estimating F0")
    
    if(~strcmp(options.fullpathM0, fullpath_movie))
        [M0, specs0] = rw.h5readMovie(options.fullpathM0); 
        M_mean = mean(M0, 3);
        clear('M0');
    elseif(specs.extra_specs.isKey("expBaseline_end"))
        M_mean = specs.extra_specs("expBaseline_end");
%     elseif(specs.extra_specs.isKey("expBaseline_A"))
%         M_mean = specs.extra_specs("expBaseline_A");
    elseif(specs.extra_specs.isKey("mean_substracted")) 
        M_mean = specs.extra_specs("mean_substracted");
    else
        M_mean = mean(Mraw, 3);%std(Mraw, 3);%std(Mraw, 1, 3);%mean(Mraw, 3);
        Mraw = Mraw - M_mean;
    end
    
    M_mean(M_mean < 8) = NaN; %less than 8 counts
    fig_f0 = plt.getFigureByName("F0");
    im1 = imshow(M_mean, []); colormap(plt.redblue); 
    title("F_0");
    set(im1, 'AlphaData', ~isnan(M_mean));
%     subplot(1,3,1)
%     imshow(M_mean, []); colormap(plt.redblue); title("F_0");
%     subplot(1,3,2)
%     threhold = 0.15;
%     nregions = 2;
%     Mmedian_th = M_mean.*(M_mean > median(M_mean(:), 'omitnan')*threhold);
%     regions = regionprops(Mmedian_th > 0, 'PixelIdxList', 'Area' );
%     [~, order] = sort([regions.Area], 'descend');
%     regions = regions(order);
% 
%     for i_r = (nregions + 1):length(regions)
%         Mmedian_th(regions(i_r).PixelIdxList) = 0;
%     end

%     subplot(1,3,3)
%     im2 = imshow(Mmedian_th , []); colormap(plt.redblue); 
%     title("F_0, threshold " + num2str(threhold) + ", " + num2str(nregions) + " regions");
%     set(im2, 'AlphaData', (Mmedian_th > 0));


    %%
    disp("movieDFF: computing dF/F0")
    Md = Mraw./M_mean;
    nan_mask = double(any(abs(Md) < 10*median(abs(Md(abs(Md) > 0)), 'all', 'omitnan'), 3));
    nan_mask(~nan_mask) = NaN;
%     Md(abs(Md) > 10*median(abs(Md(abs(Md) > 0)), 'all', 'omitnan') ) = NaN;
%     for i_p = find(M_mean == 0)' 
%         [i_x, i_y] = ind2sub(size(M_mean), i_p);
%         Md(i_x,i_y,:) = NaN;
%     end
%     plt.getFigureByName("dF/F0");
%     plt.SliderMovie(Md)
    %%
    
    fig_traces = plt.getFigureByName("dF/F0 traces");
    mraw = squeeze(mean(Mraw, [1,2], 'omitnan'));
    md = squeeze(mean(Md, [1,2], 'omitnan'));
    plt.tracesComparison([mraw*std(md)/std(mraw), md],  ...
        'fps', specs.getFps(),  'labels', ["raw (sd norm)", "dF/F"], 'f0', 0.5)
    
    
    saveas(fig_f0, fullfile(options.diagnosticdir, filename_out + "F0.png") );
    saveas(fig_f0, fullfile(options.diagnosticdir, filename_out + "F0.fig") );
    
    saveas(fig_traces, fullfile(options.diagnosticdir, filename_out + "traces.png") );
    saveas(fig_traces, fullfile(options.diagnosticdir, filename_out + "traces.fig") );   
    %%    
    disp("movieDFF: saving output")
    
    specs_out = copy(specs);
    specs_out.AddToHistory(functionCallStruct({'fullpath_movie', 'options'}));
    specs_out.extra_specs("F0") = M_mean;
    
    summary.options = options;

    rw.h5saveMovie(fullpath_out, Md, specs_out);
    h5save( fullpath_out, summary,  'movieDFF');
end
%%

function options = defaultOptions(fullpath)

    [basepath, ~, ~, ~] = filenameSplit(fullpath, '_');
    options.fullpathM0 = fullpath;

    options.diagnosticdir = basepath + "\diagnostic\movieDFF\";
    options.outdir = basepath;
    options.skip = true;
end
%%