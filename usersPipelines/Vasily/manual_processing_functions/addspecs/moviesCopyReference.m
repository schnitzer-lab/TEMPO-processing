function fullpath_out = moviesCopyReference(fullpath_movie, fullpath_movie_ref, varargin)
    
    [basepath, filename, ext, basefilename, channel, postfix] = ...
        filenameParts(fullpath_movie);

    options = defaultOptions(basepath);
    if(~isempty(varargin))
        options = getOptions(options, varargin);
    end
    %%

    specs2 = rw.h5readMovieSpecs(fullpath_movie);
    if(~isempty(specs2.getMask()) && ~isempty(specs2.getAllenOutlines()))
        if(options.skip)
            disp("moviesCopyReference: Movie has mask & allen outlines. Skipping: " + fullpath_movie)
            return;
        else
            warning("moviesCopyReference: Movie has mask & allen outlines. Overwriting: " + fullpath_movie);
        end   
    end
    %%
    
    if (~isfolder(options.diagnosticdir)) mkdir(options.diagnosticdir); end
    %%
    
    disp("moviesCopyReference: reading frames")

    specs1 = rw.h5readMovieSpecs(fullpath_movie_ref);
%     specs2 = rw.h5readMovieSpecs(fullpath_movie);
    specs2_out = copy(specs2);
    
    F1 = specs1.extra_specs('F0');
    F2 = specs2.extra_specs('F0');
    %%

    disp("moviesCopyReference: performing registration")
    frame_fixed = imputeNaNS(F1); 
    frame_moving = imputeNaNS(F2);

    if(options.bandpass)
        lower_threshold = options.bandpass(1)/specs1.getPixSize();
        upper_threshold = options.bandpass(2)/specs1.getPixSize();
        spatial_filter = @(data) ...
            abs(smoothdata(smoothdata(data, 1, 'gaussian', upper_threshold), 2, 'gaussian', upper_threshold )-...
             smoothdata(smoothdata(data, 1, 'gaussian', lower_threshold), 2, 'gaussian', lower_threshold)); % abs case R and G sometimes are anti-correlated
    else
        spatial_filter = @(data) data; 
    end

    [Reg,regMethod, regScore] = imageReg(spatial_filter(frame_fixed), spatial_filter(frame_moving), 'linear');
    
%     frame_registered = imwarp(frame_moving, Reg.transformation,...
%     'OutputView', imref2d(size(frame_fixed)), ...
%     'SmoothEdges', true, 'FillValues', NaN, 'interp', 'linear');

    fig_reg = plt.getFigureByName('moviesCopyReference: registration');
    subplot(1,4,1)
    imshow(spatial_filter(frame_fixed),[])
    title('reference movie', 'Interpreter', 'none')
    subplot(1,4,2)
    imshow(spatial_filter(frame_moving),[])
    title('movie to align', 'Interpreter', 'none')
    subplot(1,4,3)
    imshowpair(spatial_filter(frame_fixed),spatial_filter(frame_moving))
    title('overlap initial')
    subplot(1,4,4)
    imshowpair(spatial_filter(frame_fixed),Reg.RegisteredImage)
    title('overlap registered')
    %%
    
    disp("moviesCopyReference: registering mask")

    mask_moving = imwarp(specs1.getMask(), Reg.transformation.invert,...
        'OutputView', imref2d(size(frame_moving)), ...
        'SmoothEdges', true, 'FillValues', NaN, 'interp', 'linear');
    mask_moving(1,:) = 0;
    mask_moving(:,1) = 0;
    mask_moving(end,:) = 0;
    mask_moving(:,end) = 0;
    
    specs2_out.extra_specs("mask") = ...
        repelem(mask_moving, specs2_out.binning, specs2_out.binning);
    
    fig_masks = plt.getFigureByName('moviesCopyReference: masks');
    subplot(1,2,1)
    imshow(frame_fixed.*double(specs1.getMask()), [])
    subplot(1,2,2)
    imshow(frame_moving.*double(specs2_out.getMask()), [])
    %%
    
    rw.h5writeStruct(char(fullpath_movie), ...
        specs2_out.extra_specs("mask"), '/specs/extra_specs/mask');
    %%
    disp("moviesCopyReference: registering allen")
        
    edgeOutlines_fixed = specs1.getAllenOutlines();
    edgeOutlines_moving = nan(size(edgeOutlines_fixed));
    for i_r = 1:size(edgeOutlines_fixed,3)
        region_outline = Reg.transformation.transformPointsInverse(edgeOutlines_fixed(:,:,i_r));
        edgeOutlines_moving(:,:,i_r) = region_outline;
    end
    
    specs2_out.extra_specs("allenTransform") = ...
        specs1.extra_specs('allenTransform')*Reg.transformation.T; % order? % does not account for possible rebinning
    specs2_out.extra_specs("allenMapEdgeOutline") = ...
        edgeOutlines_moving*specs2_out.binning;

    %%
    fig_allen = plt.getFigureByName("register_two_frames: allen");

    subplot(1,2,1)
    imshow(F1, []); hold on;
    plt.outlines(specs1.getAllenOutlines(),...
        '--', 'color', [0,1,0], 'LineWidth', 0.5); 
    hold off
    
    subplot(1,2,2)
    imshow(F2, []); hold on;
    % plt.outlines(edgeOutlines_fixed,...
    %     '--', 'color', [1,0,0], 'LineWidth', 0.5); 
    plt.outlines(specs2_out.getAllenOutlines(),...
        '--', 'color', [0,1,0], 'LineWidth', 0.5); 
    hold off
    drawnow;
    %%

    rw.h5writeStruct(char(fullpath_movie), ...
        specs2_out.extra_specs("allenTransform"), '/specs/extra_specs/allenTransform');
    rw.h5writeStruct(char(fullpath_movie), ...
        specs2_out.extra_specs("allenMapEdgeOutline"), '/specs/extra_specs/allenMapEdgeOutline');
    %%
    
    disp("moviesCopyReference: saving diagnostic")
    
    saveas(fig_reg, fullfile(options.diagnosticdir, filename + "_reg.png"))
    saveas(fig_reg, fullfile(options.diagnosticdir, filename + "_reg.fig"))
    saveas(fig_masks, fullfile(options.diagnosticdir, filename + "_masks.png"))
    saveas(fig_masks, fullfile(options.diagnosticdir, filename + "_masks.fig"))
    saveas(fig_allen, fullfile(options.diagnosticdir, filename + "_allen.png"))
    saveas(fig_allen, fullfile(options.diagnosticdir, filename + "_allen.fig"))
end
%%

function options = defaultOptions(basepath)
    
    options.diagnosticdir = basepath + "\diagnostic\moviesCopyReference\";

    options.bandpass = [0.0200 0.2000]; %mm
    options.skip = true;
end
%%