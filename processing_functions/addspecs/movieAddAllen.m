function  movieAddAllen(fullpath_movie, fullpath_allen, ...
    allen_points_path, allenmap_path, varargin)
    
    [basepath, filename, ~] = fileparts(fullpath_movie, '_');

    options = defaultOptions(basepath);
    if(~isempty(varargin))
        options = getOptions(options, varargin);
    end
    
    %%
    
    if (~isfolder(options.processingdir)), mkdir(options.processingdir); end
    %%
    
    fig_pts = plt.getFigureByName("movieAddAllen: points matching");
    atlas_matched_img = imread(fullpath_allen);

    points_ref_all = readmatrix(allen_points_path);
    points_ref = points_ref_all(:, 1:2);
    points_colors = points_ref_all(:, 3:5);

    points_aligned = zeros(size(points_ref));

    imshow(atlas_matched_img, []); hold on;

    for i_p = 1:size(points_aligned, 1)

        d = double(atlas_matched_img)/255 - reshape(points_colors(i_p,:), [1,1,3]);

        [row, column] = find(sqrt(sum(d.^2, 3)) < 0.2);

        if(isempty(row)), continue; end

        points_aligned(i_p, :) = [median(column), median(row)]; 
        scatter(points_aligned(i_p, 1) , points_aligned(i_p, 2), 'g.');
        text(points_aligned(i_p, 1)+2, points_aligned(i_p, 2), num2str(i_p), 'color', 'g');
    end
    hold off;

    %  if affine, affinestr='affine'; else, affinestr='nonreflectivesimilarity'; end
    tform = fitgeotrans(points_aligned, points_ref,'affine');
    %%
    load(allenmap_path); %allenmap
    
    maxsize = max(cell2mat(cellfun(@size, allenmap.edgeOutline, 'UniformOutput', false)), [], [1,2]);
    edgeOutlinesTransformed = nan(maxsize,2, length(allenmap.edgeOutline));

    for i_r = 1:length(allenmap.edgeOutline)
    %     region_outline = allenmap.edgeOutline{i_r};
        region_outline =tform.transformPointsInverse(allenmap.edgeOutline{i_r}(:,[1,2]));
        edgeOutlinesTransformed(1:size(region_outline,1),:,i_r) = region_outline;
    end

    %%
    
    specs = rw.h5readMovieSpecs(fullpath_movie);
    specs_out = copy(specs);
    specs_out.extra_specs("allenTransform") = tform.T; % does not account for possible rebinning
    specs_out.extra_specs("allenMapEdgeOutline") = edgeOutlinesTransformed*specs_out.binning;
    
    rw.h5writeStruct(char(fullpath_movie), tform.T, '/specs/extra_specs/allenTransform');
    rw.h5writeStruct(char(fullpath_movie), edgeOutlinesTransformed*specs_out.binning, '/specs/extra_specs/allenMapEdgeOutline');
%     rw.h5saveMovieSpecs(fullpath_movie, specs_out, 'rewrite', false);
    %%
    if(options.plotmean)
        [M, specs] = rw.h5readMovie(fullpath_movie);
        Mplot = std(M, [],3, 'omitnan');%max(M, [], 3);% % mean(M,3, 'omitnan');%

        edgeOutlines = specs.getAllenOutlines();
        
        fig_algn = plt.getFigureByName("aligned");
        imshow(plt.saturate(Mplot, 0.01), []); hold on;
 %%
        colormap(plt.redblue)
        for i_r = 1:length(allenmap.edgeOutline)
            plot(edgeOutlines(:,1,i_r), edgeOutlines(:,2,i_r), '--', 'color', [0,0.25,0], 'LineWidth', 1); hold on;
        end
        scatter(points_aligned(:,1), points_aligned(:,2), '+')
        hold off;
        
        %%
        saveas(fig_algn, fullfile(options.processingdir, filename + "_aligned.png"))
        saveas(fig_algn, fullfile(options.processingdir, filename + "_aligned.fig"))
    end
    
    saveas(fig_pts, fullfile(options.processingdir, filename + "_points.png"))
    saveas(fig_pts, fullfile(options.processingdir, filename + "_points.fig"))


%     fig_trace = plt.getFigureByName("Traces comparison");
%     plt.tracesComparison([squeeze(mean(M, [1,2])), squeeze(mean(Mout, [1,2]))], ...
%         'fps', specs.fps, 'labels', ["spatially-averaged trace", "spatially-averaged trace after masking"]) 
end
%%

function options = defaultOptions(basepath)
    
    options.processingdir = basepath + "\diagnostic\movieAddAllen\";
    options.plotmean = true;
end
%%