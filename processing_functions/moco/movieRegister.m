function fullpath_out = movieRegister(fullpath_movie, fullpath_ref, varargin)
    
    [basepath, filename, ext] = fileparts(fullpath_movie);

    options = parseInputs(basepath, varargin{:});
    %%
    
    if (~isfolder(options.outdir)), mkdir(options.outdir); end
    if (~isfolder(options.processingdir)), mkdir(options.processingdir); end
    if (~isfolder(options.diagnosticdir)), mkdir(options.diagnosticdir); end

    filename_out = filename+options.postfix_new;
    fullpath_out = fullfile(options.outdir, filename_out + ext);
    
    if (isfile(fullpath_out))
        if(options.skip)
            disp("movieRegister: Output file exists. Skipping: " + fullpath_out)
            return;
        else
            warning("movieRegister: Output file exists. Deleting: " + fullpath_out);
            delete(fullpath_out);
        end     
    end
    %%
    
    disp("movieRegister: reading movie")
    
    [Mref, ~] = rw.h5readMovie(fullpath_ref);
    median_fixed = medianOfMedians(Mref, options.nmedian);
%     delete('Mref')

    [M, specs] = rw.h5readMovie(fullpath_movie);
    if(~isempty(options.flipax)), M = flip(M, options.flipax); end
    median_moving = medianOfMedians(M, options.nmedian);    
    %%

    disp("movieRegister: computing the transform")
    
    if(~isempty(options.bandpass))
        lower_threshold = 2*round(options.bandpass(1)/specs.getPixSize()/2)+1;
        upper_threshold = 2*round(options.bandpass(2)/specs.getPixSize()/2)+1;

        spatial_filter = @(data) ...
            smoothdata(smoothdata(data, 1, 'gaussian', upper_threshold), 2, 'gaussian', upper_threshold)-...
            smoothdata(smoothdata(data, 1, 'gaussian', lower_threshold), 2, 'gaussian', lower_threshold);
        hann2d = cast(hann(size(median_fixed,1))*hann(size(median_fixed,2))', class(median_fixed));
    
        template_fixed  = spatial_filter(median_fixed).*hann2d; 
        template_moving = spatial_filter(median_moving).*hann2d;
    else
        template_fixed = median_fixed;
        template_moving = median_moving;
    end
    %%

    plt.getFigureByName("movieRegister: templates overlap")
    subplot(1,2,1)
    imshowpair(template_moving, template_fixed)
    title("initial")

    plt.getFigureByName("movieRegister: templates")
    subplot(1,3,1)
    imshow(template_fixed, [])
    title("fixed")
    subplot(1,3,2)
    imshow(template_moving, [])
    title("initial")
    %%

    ref_fixed = imref2d(size(template_fixed));
    
    rot = @(t) [cosd(t) sind(t); -sind(t) cosd(t)];

    tform0 = rigid2d(rot(options.angle0), options.shifts0/specs.getPixSize());
    template_reg0 = imwarp(template_moving, tform0, 'OutputView', ref_fixed, ...
        'SmoothEdges', true, 'FillValues', 0, 'interp', options.interp);
    %%
    
    tform_cor = imregcorr(template_reg0, template_fixed, ...
        'transformtype', 'rigid', 'window', false);
    template_cor = imwarp(template_reg0, tform_cor, 'OutputView', ref_fixed, ...
        'SmoothEdges', true, 'FillValues', 0, 'interp', options.interp);

    [opt, met] = imregconfig("multimodal");
    tform_mul =  imregtform(template_cor, template_fixed,'rigid', opt, met);

    tform_full = rigid2d(tform_mul.T*tform_cor.T*tform0.T);
    template_registered = imwarp(template_moving, tform_full, 'OutputView', ref_fixed, ...
        'SmoothEdges', true, 'FillValues', options.fillval, 'interp', options.interp);
    %%

    nan_mask = isnan(template_registered) | isnan(template_fixed) | isnan(template_moving);
    corr_mov = corr(template_moving(~nan_mask), template_fixed(~nan_mask));
    corr_reg = corr(template_registered(~nan_mask), template_fixed(~nan_mask));

    fig_overlap = plt.getFigureByName("movieRegister: templates overlap");
    subplot(1,2,1);
    title(sprintf("initial (r=%.2f)", corr_mov))
    subplot(1,2,2);
    imshowpair(template_registered, template_fixed);
    title(sprintf("transformed (r=%.2f)", corr_reg))
    
    fig_sbs = plt.getFigureByName("movieRegister: templates");
    subplot(1,3,3);
    imshow(template_registered, []);
    title("transformed");
    %%

    saveas(fig_overlap, fullfile(options.diagnosticdir, filename_out + "_overlap.png"))
    saveas(fig_overlap, fullfile(options.diagnosticdir, filename_out + "_overlap.fig"))
    saveas(fig_sbs, fullfile(options.diagnosticdir, filename_out + "_sbs.png"))
    saveas(fig_sbs, fullfile(options.diagnosticdir, filename_out + "_sbs.fig"))
    %%

    if(any(abs(abs(tform_cor.T(3,1:2)))*specs.getPixSize() > options.shift_max))
        error("movieRegister: template registration failed - shift too big");
    end
    if(abs(atan2d(tform_cor.T(2,1), tform_cor.T(1,1))) > options.angle_max)
        error("movieRegister: template registration failed - angle too big");
    end
    if(corr_reg < options.corr_min)
        error("movieRegister: template registration failed - final correlation too low");        
    end
    %%
    
    disp("movieRegister: applying transform to the full movie")
    
    M_reg = nan(size(M), class(M));
    parfor i_f = 1:size(M,3)
        frame_moving = M(:,:,i_f);
        frame_registered = imwarp(frame_moving, tform_full, 'OutputView', ref_fixed, ...
            'SmoothEdges', true, 'FillValues', options.fillval, 'interp', options.interp);
        M_reg(:,:,i_f) = frame_registered;
    end
    median_reg = medianOfMedians(M_reg, options.nmedian);
    %%

    fig_med = plt.getFigureByName("movieRegister: medians");
    subplot(1,3,1); imshow(median_fixed, []); title("fixed");
    subplot(1,3,2); imshow(median_moving, []); title("initial");
    subplot(1,3,3); imshow(median_reg, []); title("transformed");
    drawnow(); 
    %%
       
    disp("movieRegister: saving output")

    specs_out = copy(specs);
    specs_out.AddToHistory(functionCallStruct({'fullpath_movie','fullpath_ref','options'})); 

    jsonCorr = jsonencode(struct('corr_mov', corr_mov, 'corr_reg', corr_reg));
    jsonTform = jsonencode(struct('shift', tform_full.Translation*specs.getPixSize(), ...
                                  'angle', atan2d(tform_full.Rotation(2,1), tform_full.Rotation(1,1))));
    %%
    
    rw.h5saveMovie(fullpath_out, M_reg, specs_out);
    saveas(fig_med, fullfile(options.diagnosticdir, filename_out + "_median.png"));
    saveas(fig_med, fullfile(options.diagnosticdir, filename_out + "_median.fig"));

    fid = fopen(fullfile(options.processingdir, 'corr.json'), 'w'); 
    fwrite(fid, jsonCorr, 'char');
    fclose(fid);
    fid = fopen(fullfile(options.processingdir, 'tform.json'), 'w'); 
    fwrite(fid, jsonTform, 'char');
    fclose(fid);
end
%%

function [options,p] = parseInputs(basepath, varargin)
    
    p = inputParser();
    isinrange = @(x,a,b) isnumeric(x)&all((x>=a)&(x<=b));

    p.addParameter('diagnosticdir', ...
        fullfile(basepath, "\diagnostic\movieRegister\"), @(s) isstring(s)|ischar(s));
    p.addParameter('processingdir', ...
        fullfile(basepath, "\processing\movieRegister\"), @(s) isstring(s)|ischar(s));

    p.addParameter('nmedian', 10000);

    p.addParameter('bandpass', [0.05, 0.5], @(x) isinrange(x,0,Inf)); % mm
    p.addParameter('flipax', 2);
    p.addParameter('shifts0', [0, 0], @(x) isinrange(x,0,Inf)); % mm
    p.addParameter('angle0', 0, @(x) isinrange(x,-180,180)); % degree

    p.addParameter('interp', 'linear');
    p.addParameter('fillval', NaN);

    p.addParameter('shift_max', Inf, @(x) isinrange(x,0,Inf)); % mm
    p.addParameter('angle_max', Inf, @(x) isinrange(x,0,Inf)); % degree
    p.addParameter('corr_min', 0, @(x) isinrange(x,0,1));

    p.addParameter('outdir', basepath, @(s) isstring(s)|ischar(s));
    p.addParameter('postfix_new', "_reg", @(s) isstring(s)|ischar(s));
    p.addParameter('skip', true, @(x) (x==true)|(x==false));

    p.parse(varargin{:});
    options = p.Results;
end