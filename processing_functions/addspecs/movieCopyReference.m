function movieCopyReference(fullpath_movie, fullpath_movie_ref, varargin)
    
    [basepath, filename, ~] = fileparts(fullpath_movie);

    options = parseInputs(basepath, varargin{:});
    %%

    specs_mov = rw.h5readMovieSpecs(fullpath_movie);
    if(~isempty(specs_mov.getMask()) || ...
       ~isempty(specs_mov.getAllenOutlines()) || ...
       ~isempty(specs_mov.getCustomOutlines()) )
        if(options.skip)
            displog("Movie has mask or outlines. Skipping: " + fullpath_movie)
            return;
        else
            warning("movieCopyReference: Movie has mask or outlines. Overwriting: " + fullpath_movie);
        end   
    end
    %%
    
    if (~isfolder(options.diagnosticdir)), mkdir(options.diagnosticdir); end
    %%
    
    if(isempty(fullpath_movie_ref))

        displog("looking for reference file")

        files = dir(fullfile(options.folder_ref, ...
            specs_mov.mouse_id() + "_c" + specs_mov.channel_id + "*.h5"));

        if(length(files) < 1)
            error("no reference for the mouse " + ...
                specs_mov.mouse_id() + " in " + options.folder_ref)
        elseif(length(files) == 1)
            fullpath_movie_ref = fullfile(files(1).folder, files(1).name);
        else
            fullpath_movie_ref = selectClosestReference(files, specs_mov, options);
        end
    end
    %%
    
    displog("reading frames")

    specs_ref = rw.h5readMovieSpecs(fullpath_movie_ref);
    % specs_mov = rw.h5readMovieSpecs(fullpath_movie);
    specs_out = copy(specs_mov);

    F1 = specs_ref.extra_specs('F0');
    if(specs_mov.extra_specs.isKey('F0'))
        F2 = specs_mov.extra_specs('F0');
    elseif(specs_mov.extra_specs.isKey('expBaseline_end'))
        F2 = specs_mov.extra_specs('expBaseline_end');
    else
        M = rw.h5readMovie(fullpath_movie);
        F2 = mean(M,3);
    end
    %%

    if(specs_mov.binning ~= specs_ref.binning)
        % warning("movieCopyReference: binnign mismatch");
        bin = specs_mov.binning/specs_ref.binning;
        if(bin-round(bin))
            error("movieCopyReference: binnign mismatch");
        end
        F1 = mm.DownsampleSpace(F1, bin);
        specs_ref.AddBinning(bin);
    end
    %%

    displog("performing registration")
    frame_fixed = imputeNaNS(F1); 
    frame_moving = imputeNaNS(F2);
    
    if(~isempty(options.bandpass))
        lower_threshold = 2*round(options.bandpass(1)/specs_mov.getPixSize()/2)+1;
        upper_threshold = 2*round(options.bandpass(2)/specs_mov.getPixSize()/2)+1;

        spatial_filter = @(data) ...
            smoothdata(smoothdata(data, 1, 'gaussian', upper_threshold), 2, 'gaussian', upper_threshold)-...
            smoothdata(smoothdata(data, 1, 'gaussian', lower_threshold), 2, 'gaussian', lower_threshold);
        hann2d_fixed = cast(hann(size(frame_fixed,1))*hann(size(frame_fixed,2))', class(frame_fixed));
        hann2d_moving = cast(hann(size(frame_moving,1))*hann(size(frame_moving,2))', class(frame_moving));
    
        template_fixed  = spatial_filter(frame_fixed).*hann2d_fixed; 
        template_moving = spatial_filter(frame_moving).*hann2d_moving;
    else
        template_fixed = frame_fixed;
        template_moving = frame_moving;
    end
    %%

    ref_fixed = imref2d(size(template_fixed));
    ref_moving = imref2d(size(template_moving));
    center = [mean(ref_fixed.XWorldLimits), mean(ref_fixed.YWorldLimits)];
    %%

    template_moving_regref = imwarp(template_moving, ref_moving, rigid2d(), ...
        'OutputView', ref_fixed, ...
        'SmoothEdges', true, 'FillValues', NaN, 'interp', options.interp);

    plt.getFigureByName("movieCopyReference: templates overlap");
    subplot(1,2,1)
    imshowpair(template_moving_regref, template_fixed)
    title("initial")
    %%

    rot = @(t) [cosd(t) sind(t); -sind(t) cosd(t)];

    % tform0 = rigid2d(rot(-options.angle0), options.shifts0/specs_mov.getPixSize());
    tform00 = rigid2d(rot(0), [center(1), center(2)]); 
    tform01 = rigid2d(rot(-options.angle0), [0, 0]); 
    tform02 = rigid2d(rot(0), options.shifts0/specs_mov.getPixSize()); 
    
    % move origin to center, rotate, shift, move origin back
    tform0 = rigid2d(tform00.invert.T*tform02.T*tform01.T*tform00.T);

    template_moving_reg0 = imwarp(template_moving, ref_moving, tform0, 'OutputView', ref_fixed, ...
        'SmoothEdges', true, 'FillValues', 0, 'interp', options.interp);
    
    % subplot(1,2,2)
    % imshowpair(template_moving_reg0, template_fixed)
    %%
    
    [opt, met] = imregconfig("monomodal");
    % [opt, met] = imregconfig("multimodal");
    tform_mul =  imregtform(template_moving_reg0, ref_fixed, template_fixed, ref_fixed,...
        'rigid', opt, met);

    tform_full = rigid2d(tform_mul.T*tform0.T); % *tform_cor.T
    template_moving_reg = imwarp(template_moving, ref_moving, tform_full, 'OutputView', ref_fixed, ...
        'SmoothEdges', true, 'FillValues', options.fillval, 'interp', options.interp);
    
    % subplot(1,2,2)
    % imshowpair(template_moving_reg, template_fixed)
    %%

    template_fixed_movref = imwarp(template_fixed, ref_fixed, rigid2d(), 'OutputView', ref_moving, ...
        'SmoothEdges', true, 'FillValues', options.fillval, 'interp', options.interp);
    template_fixed_reg = imwarp(template_fixed, ref_fixed, tform_full.invert, 'OutputView', ref_moving, ...
        'SmoothEdges', true, 'FillValues', options.fillval, 'interp', options.interp);
    %%

    nan_mask = isnan(template_moving) | isnan(template_fixed_reg) | isnan(template_fixed_movref);
    corr_mov = corr(template_moving(~nan_mask), template_fixed_movref(~nan_mask));
    corr_reg = corr(template_moving(~nan_mask), template_fixed_reg(~nan_mask));

    fig_overlap = plt.getFigureByName("movieCopyReference: templates overlap");
    subplot(1,2,1);
    title(sprintf("initial (r=%.2f)", corr_mov))
    subplot(1,2,2);
    imshowpair(template_moving_reg, template_fixed);
    title(sprintf("transformed (r=%.2f)", corr_reg)) 

    sgtitle([string(basepath), string(filename)], 'Interpreter', 'None')
    %%

    if(any(abs(abs(tform_full.T(3,1:2)))*specs_mov.getPixSize() > options.shift_max))
        error("movieCopyReference: template registration failed - shift too big");
    end
    if(abs(atan2d(tform_full.T(2,1), tform_full.T(1,1))) > options.angle_max)
        error("movieCopyReference: template registration failed - angle too big");
    end
    if(corr_reg < options.corr_min || corr_mov-corr_reg > 1e-8)
        error("movieCopyReference: template registration failed - final correlation too low");        
    end
    %%

    displog("registering mask")

    mask_moving = imwarp(int32(specs_ref.getMask()), tform_full.invert,...
        'OutputView', imref2d(size(frame_moving)), ...
        'SmoothEdges', true, 'FillValues', NaN, 'interp', 'linear');
    mask_moving(1,:) = 0; mask_moving(:,1) = 0;
    mask_moving(end,:) = 0; mask_moving(:,end) = 0;
    
    specs_out.extra_specs("mask") = ...
        repelem(mask_moving, specs_out.binning, specs_out.binning);
    
    fig_masks = plt.getFigureByName('movieCopyReference: masks');
    subplot(1,2,1)
    imshow(frame_fixed.*double(specs_ref.getMask()), [])
    title("reference alignmet")
    subplot(1,2,2)
    imshow(frame_moving.*double(specs_out.getMask()), [])
    title("target alignmet")

    sgtitle([string(basepath), string(filename)], 'Interpreter', 'None')
    %%
    displog("registering allen")
        
    allenOutlines_fixed = specs_ref.getAllenOutlines();
    allenOutlines_moving = nan(size(allenOutlines_fixed));

    if(~isempty(allenOutlines_fixed))
    
        for i_r = 1:size(allenOutlines_fixed,3)
            region_outline = tform_full.transformPointsInverse(allenOutlines_fixed(:,:,i_r));
            allenOutlines_moving(:,:,i_r) = region_outline;
        end
        
        specs_out.extra_specs("allenTransform") = ...
            specs_ref.extra_specs('allenTransform')*tform_full.T; % order? % does not account for possible rebinning
        specs_out.extra_specs("allenMapEdgeOutline") = ...
            allenOutlines_moving*specs_out.binning;
    end

    customOutlines_fixed = specs_ref.getCustomOutlines();
    customOutlines_moving = nan(size(customOutlines_fixed));

    if(~isempty(customOutlines_fixed))
    
        for i_r = 1:size(customOutlines_fixed,3)
            region_outline = tform_full.transformPointsInverse(customOutlines_fixed(:,:,i_r));
            customOutlines_moving(:,:,i_r) = region_outline;
        end
        
        specs_out.extra_specs("customOutlines") = ...
            customOutlines_moving*specs_out.binning;
    end
    %%

    fig_allen = plt.getFigureByName("register_two_frames: outlines");

    subplot(1,2,1)
    imshow(plt.saturate(F1, [0, 0.95]), []); hold on;

    plt.outlines(specs_ref.getAllenOutlines(), [], [],...
        '--', 'color', [0,1,0], 'LineWidth', 0.5); 
    plt.outlines(specs_ref.getCustomOutlines(), [], [],...
        '--', 'color', [1,0,0], 'LineWidth', 0.5); 
    title("reference alignmet")
    hold off
    
    subplot(1,2,2)
    imshow(plt.saturate(F2, [0, 0.95]), []); hold on;
    plt.outlines(specs_out.getAllenOutlines(), [], [],...
        '--', 'color', [0,1,0], 'LineWidth', 0.5); 
    plt.outlines(specs_out.getCustomOutlines(), [], [],...
        '--', 'color', [1,0,0], 'LineWidth', 0.5); 
    hold off
    title("target alignmet")
    drawnow;
    
    sgtitle([string(basepath), string(filename)], 'Interpreter', 'None')
    %%

    displog("saving aligned")
    
    rw.h5writeStruct(char(fullpath_movie), ...
        specs_out.extra_specs("mask"), '/specs/extra_specs/mask');
    
    if(~isempty(specs_out.getAllenOutlines()))
        rw.h5writeStruct(char(fullpath_movie), ...
            specs_out.extra_specs("allenTransform"), '/specs/extra_specs/allenTransform');
        rw.h5writeStruct(char(fullpath_movie), ...
            specs_out.extra_specs("allenMapEdgeOutline"), '/specs/extra_specs/allenMapEdgeOutline');
    end

    if(~isempty(specs_out.getCustomOutlines()))
        rw.h5writeStruct(char(fullpath_movie), ...
            specs_out.extra_specs("customOutlines"), '/specs/extra_specs/customOutlines');
    end
    %%
    
    displog("saving diagnostic")
    
    saveas(fig_overlap, fullfile(options.diagnosticdir, filename + "_reg_overlap.png"))
    saveas(fig_overlap, fullfile(options.diagnosticdir, filename + "_reg_overlap.fig"))
    saveas(fig_masks, fullfile(options.diagnosticdir, filename + "_masks.png"))
    saveas(fig_masks, fullfile(options.diagnosticdir, filename + "_masks.fig"))

    saveas(fig_allen, fullfile(options.diagnosticdir, filename + "_allen.png"))
    saveas(fig_allen, fullfile(options.diagnosticdir, filename + "_allen.fig"))
end
%%

function fullpath_movie_ref = selectClosestReference(files, specs_mov, options)

    displog("more than one reference for the mouse " + ...
        specs_mov.mouse_id() + " in " + options.folder_ref + ...
        " - selecting the one with the closest recording date")

    date_mov = datetime(specs_mov.extra_specs('recordingDate'));

    date_refs = NaT(length(files), 1);
    for i_f = 1:length(files)
        fullpath_ref_i = fullfile(files(i_f).folder, files(i_f).name);
        specs_ref_i = rw.h5readMovieSpecs(fullpath_ref_i);
        if(specs_ref_i.extra_specs.isKey('recordingDate'))
            date_refs(i_f) = datetime(specs_ref_i.extra_specs('recordingDate'));
        end
    end

    if(all(isnat(date_refs)))
        error("more than one reference for the mouse " + ...
            specs_mov.mouse_id() + " in " + options.folder_ref + ...
            " and none have a recording date to select the closest one")
    end

    [date_diff_min, i_best] = min(abs(date_refs - date_mov));
    fullpath_movie_ref = fullfile(files(i_best).folder, files(i_best).name);

    displog("selected reference: " + files(i_best).name + ...
        " (" + string(date_diff_min) + " from target recording date)")
end
%%

function [options,p] = parseInputs(basepath, varargin)
    
    p = inputParser();
    isinrange = @(x,a,b) isnumeric(x)&all((x>=a)&(x<=b));

    p.addParameter('diagnosticdir', ...
        fullfile(basepath, "\diagnostic\movieCopyReference\"), @(s) isstring(s)|ischar(s));
  
    p.addParameter('bandpass', [0.05, 0.5], @(x) isinrange(x,0,Inf)); % mm
    p.addParameter('shifts0', [0, 0], @(x) isnumeric(x)); % mm
    p.addParameter('angle0', 0, @(x) isinrange(x,-180,180)); % degree

    p.addParameter('interp', 'linear');
    p.addParameter('fillval', NaN);

    p.addParameter('shift_max', Inf, @(x) isinrange(x,0,Inf)); % mm
    p.addParameter('angle_max', Inf, @(x) isinrange(x,0,Inf)); % degree
    p.addParameter('corr_min', 0.3, @(x) isinrange(x,0,1));

    p.addParameter('skip', true, @(x) (x==true)|(x==false));
    
    p.addParameter('folder_ref', "N:\GEVI_Wave\MiceAlignment\", @(s) isstring(s)|ischar(s));

    p.parse(varargin{:});
    options = p.Results;
end