function fullpath_out = movieMaskReshape(fullpath_movie, mask, varargin)

    [basepath, filename, ext] = fileparts(fullpath_movie);

    options = parseInputs(basepath, varargin{:});
    %%

    fullpath_out = fullfile(options.outdir, filename+options.postfix_new+ext);

    if (isfile(fullpath_out))
        if(options.skip)
            displog("Output file exists. Skipping: " + fullpath_out)
            return;
        else
            warning("movieMaskReshape: Output file exists. Deleting: " + fullpath_out);
            delete(fullpath_out);
        end
    end

    if(~isfolder(options.outdir)), mkdir(options.outdir); end
    if(~isfolder(options.diagnosticdir)), mkdir(options.diagnosticdir); end
    %%

    warning("movieMaskReshape: use with caution. Pipeline functions are " + ...
        "unaware of this reshaping and will treat pixels as spatially neighboring")
    %%
    displog("reading mask and movie")

    if(ischar(mask) || isstring(mask))
        mask_image = imread(char(mask));
        if(size(mask_image, 3) > 1), mask_image = rgb2gray(mask_image); end
        mask = mask_image;
    end
    mask = logical(mask);

    [M, specs] = rw.h5readMovie(fullpath_movie);
    %%

    displog("reshaping to minimal square")

    orig_size = size(M, [1,2]);
    n_unmasked = nnz(mask);
    side = ceil(sqrt(n_unmasked));

    M_flat = reshape(M, [], size(M,3));
    pix_data = M_flat(mask(:), :);
    if(isinteger(pix_data)), pix_data = single(pix_data); end

    pix_padded = NaN(side^2, size(M,3), 'like', pix_data);
    pix_padded(1:n_unmasked, :) = pix_data;
    M_square = reshape(pix_padded, side, side, size(M,3));
    %%

    displog("generating and saving plots")
    savePlots( ...
        getStatFrame(M, options.frametype), ...
        getStatFrame(M_square, options.frametype), ...
        mask, side, specs, filename, options);
    %%

    displog("saving")

    specs_out = copy(specs);
    specs_out.extra_specs("maskreshape_mask") = mask;
    specs_out.AddToHistory(functionCallStruct({'fullpath_movie', 'mask', 'options'}));

    rw.h5saveMovie(fullpath_out, M_square, specs_out);
end
%%

function options = parseInputs(basepath, varargin)

    p = inputParser();

    p.addParameter('outdir', basepath);
    p.addParameter('diagnosticdir', fullfile(basepath, 'diagnostic', 'maskReshape'));

    p.addParameter('postfix_new', "_maskrshp");
    p.addParameter('skip', true);
    p.addParameter('frametype', "mean"); % "mean", "std"

    p.parse(varargin{:});
    options = p.Results;
end
%%

function frame = getStatFrame(M, frametype)
    switch frametype
        case "mean"
            frame = mean(M, 3, 'omitnan');
        case "std"
            frame = std(M, [], 3, 'omitnan');
        otherwise
            error("movieMaskReshape: unknown frametype " + frametype);
    end
end
%%

function savePlots(frame_orig, frame_sq, mask_final, side, ...
    specs, filename, options)

    mask_nan = nan(size(mask_final)); mask_nan(mask_final) = 1;

    % frame_orig = getStatFrame(M, options.frametype, specs);
    
    frame_masked = frame_orig.*mask_nan;
    % frame_sq = getStatFrame(M_square, options.frametype, specs);
    %%

    fig = plt.getFigureByName("movieMaskReshape");
    fig.Position(3:4) = [1200, 800];

    subplot(2,3,1); imshow(plt.saturate(frame_orig, 0.01), []);
    colormap(gca, plt.redbeige); 
    title("original (" + options.frametype + ")" + ...
        sprintf(", %dx%d pix", size(frame_orig,2), size(frame_orig,1)))
    cl = clim();

    subplot(2,3,2); 
    im=imshow(plt.saturate(frame_masked, 0.01), []);
    colormap(gca, plt.redbeige); 
    set(im, 'AlphaData', mask_final)
    title("masked" + ...
        sprintf(", %d pix", numel(frame_orig)))
    clim(cl);

    subplot(2,3,3); 
    im = imshow(plt.saturate(frame_sq, 0.01), []);
    colormap(gca, plt.redbeige); 
    title("reshaped"+ ...
        sprintf(", %dx%d pix", size(frame_sq,2), size(frame_sq,1)))
    set(im, 'AlphaData', ~isnan(frame_sq))
    clim(cl);
    %%

    n_unmasked = sum(mask_final(:));

    [rr, cc] = ndgrid(0:(size(mask_final,1)-1), 0:(size(mask_final,2)-1));
    distmap = sqrt(rr.^2 + cc.^2);
    % distmap_masked = distmap.*mask_nan;

    dist_padded = NaN(side^2, 1);
    dist_flat = distmap(:);
    dist_padded(1:n_unmasked) = dist_flat(mask_final(:));
    dist_sq = reshape(dist_padded, side, side);
    %%

    subplot(2,3,4)
    imshow(distmap, []);
    title("distance from (0,0)")
    colormap(gca, 'turbo');
    cl = clim();

    
    subplot(2,3,5); 
    im = imshow(distmap.*mask_nan, []);
    colormap(gca, 'turbo')
    set(im, 'AlphaData', mask_final)
    clim(cl);

    subplot(2,3,6); 
    im=imshow(dist_sq, []);
    colormap(gca, 'turbo');
    set(im, 'AlphaData', ~isnan(frame_sq))
    clim(cl);
    %%

    saveas(fig, fullfile(options.diagnosticdir, filename + "_masksquare" + ".png"))
    saveas(fig, fullfile(options.diagnosticdir, filename + "_masksquare" + ".fig"))
end
%%
