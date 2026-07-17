function fullpath_out = movieMaskReshapeUndo(fullpath_movie, varargin)
% Reverses movieMaskReshape: reads a movie previously packed into a
% minimal square frame, unpacks its pixels using the mask stored in
% extra_specs("maskreshape_mask"), and restores them to their original
% frame layout (unmasked pixels set to NaN), saving diagnostic plots
% comparing the reshaped and reconstructed frames.
%
%   fullpath_out = movieMaskReshapeUndo(fullpath_movie)
%   fullpath_out = movieMaskReshapeUndo(___, Name, Value)
%
%   Required input:
%     fullpath_movie - full path to the reshaped movie .h5 file, as
%                      produced by movieMaskReshape (must contain the
%                      "maskreshape_mask" entry in extra_specs)
%
%   Name-Value arguments:
%     outdir         - output directory for the reconstructed movie
%                      (default: same folder as fullpath_movie)
%     diagnosticdir  - output directory for diagnostic plots
%                      (default: <outdir>/diagnostic/maskReshape)
%     postfix_new    - postfix appended to the output filename
%                      (default: "_undomaskrshp")
%     skip           - if true, skip processing when the output file
%                      already exists; if false, delete and recompute it
%                      (default: true)
%     frametype      - summary statistic used for the diagnostic frame,
%                      either "mean" or "std" (default: "mean")
%
%   Output:
%     fullpath_out   - full path to the saved reconstructed movie .h5 file

    [basepath, filename, ext] = fileparts(fullpath_movie);

    options = parseInputs(basepath, varargin{:});
    %%

    fullpath_out = fullfile(options.outdir, filename+options.postfix_new+ext);

    if (isfile(fullpath_out))
        if(options.skip)
            displog("Output file exists. Skipping: " + fullpath_out)
            return;
        else
            warning("movieMaskReshapeUndo: Output file exists. Deleting: " + fullpath_out);
            delete(fullpath_out);
        end
    end

    if(~isfolder(options.outdir)), mkdir(options.outdir); end
    if(~isfolder(options.diagnosticdir)), mkdir(options.diagnosticdir); end
    %%

    displog("reading reshaped movie")

    [M_square, specs] = rw.h5readMovie(fullpath_movie);

    if(~specs.extra_specs.isKey("maskreshape_mask"))
        error("movieMaskReshapeUndo: no 'maskreshape_mask' found in extra_specs -- " + ...
            "movie was not produced by movieMaskReshape");
    end
    mask = specs.extra_specs("maskreshape_mask");
    %%

    displog("reconstructing original frame layout")

    orig_size = size(mask);
    n_unmasked = nnz(mask);
    nframes = size(M_square, 3);

    M_flat_sq = reshape(M_square, [], nframes);
    pix_data = M_flat_sq(1:n_unmasked, :);

    M_flat = NaN(prod(orig_size), nframes, 'like', pix_data);
    M_flat(logical(mask(:)), :) = pix_data;
    M = reshape(M_flat, orig_size(1), orig_size(2), nframes);
    %%

    displog("generating and saving plots")
    savePlots( ...
        getStatFrame(M_square, options.frametype), ...
        getStatFrame(M, options.frametype), ...
        filename, options);
    %%

    displog("saving")

    specs_out = copy(specs);
    specs_out.AddToHistory(functionCallStruct({'fullpath_movie', 'options'}));

    rw.h5saveMovie(fullpath_out, M, specs_out);
end
%%

function options = parseInputs(basepath, varargin)

    p = inputParser();

    p.addParameter('outdir', basepath);
    p.addParameter('diagnosticdir', fullfile(basepath, 'diagnostic', 'maskReshape'));

    p.addParameter('postfix_new', "_undomaskrshp");
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
            error("movieMaskReshapeUndo: unknown frametype " + frametype);
    end
end
%%

function savePlots(frame_before, frame_after, filename, options)

    fig = plt.getFigureByName("movieMaskReshapeUndo");
    fig.Position(3:4) = [900, 450];

    subplot(1,2,1); im = imshow(plt.saturate(frame_before, 0.01), []);
    colormap(gca, plt.redbeige);
    set(im, 'AlphaData', ~isnan(frame_before))
    title("before (reshaped)" + ...
        sprintf(", %dx%d pix", size(frame_before,2), size(frame_before,1)))
    cl = clim();

    subplot(1,2,2); im = imshow(plt.saturate(frame_after, 0.01), []);
    colormap(gca, plt.redbeige);
    set(im, 'AlphaData', ~isnan(frame_after))
    title("after (reconstructed)" + ...
        sprintf(", %dx%d pix", size(frame_after,2), size(frame_after,1)))
    clim(cl);
    %%

    saveas(fig, fullfile(options.diagnosticdir, filename + "_undomasksquare" + ".png"))
    saveas(fig, fullfile(options.diagnosticdir, filename + "_undomasksquare" + ".fig"))
end
%%
