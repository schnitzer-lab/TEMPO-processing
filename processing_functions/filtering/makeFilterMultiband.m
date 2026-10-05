function [conv_trans] = makeFilterMultiband(filterpath, f0s, wps, varargin)

    f0s = f0s(:)';
    nbands = numel(f0s);
    if(isscalar(wps)), wps = repmat(wps, 1, nbands); end
    wps = wps(:)';

    options = DefaultOptions(wps);
    if(~isempty(varargin))
        options=getOptions(options,varargin);
    end
    if(isscalar(options.wr)), options.wr = repmat(options.wr, 1, nbands); end
    if(isscalar(options.attn_r)), options.attn_r = repmat(options.attn_r, 1, nbands); end
    if(isempty(options.attn_l)), options.attn_l = options.attn_r; end
    if(isscalar(options.attn_l)), options.attn_l = repmat(options.attn_l, 1, nbands); end
    if(isscalar(options.rppl)), options.rppl = repmat(options.rppl, 1, nbands); end

    if(options.verbose), displog("Creating multiband filter"); end

    kernels = cell(1, nbands);
    for i = 1:nbands
        designSpecs = fdesign.bandpass('Fst1,Fp1,Fp2,Fst2,Ast1,Ap,Ast2', ...
               (f0s(i)-wps(i)-options.wr(i))*2/options.fps, (f0s(i)-wps(i))*2/options.fps, ...
               (f0s(i)+wps(i))*2/options.fps, (f0s(i)+wps(i)+options.wr(i))*2/options.fps,...
               mag2db(options.attn_l(i)), mag2db(1+options.rppl(i)), mag2db(options.attn_r(i)));

        H = design(designSpecs, 'equiripple', 'MinOrder', 'even');
        kernels{i} = impz(H); %same as cell2mat({H.Numerator}')' for FIR filters

        if(options.verbose), displog("successfully designed " + i + "/" + nbands + " filters"); end
    end

    conv_trans = sumKernelsCentered(kernels);

    if(options.verbose), displog("Filter created"); end

    writematrix(conv_trans, filterpath);

    fig = plt.getFigureByName('Convolutional Filter Illustration');
    set(gcf, 'Units', 'Normalized', 'OuterPosition', [0.5, 0.5, .4, 0.3])
    plt.ConvolutionalMultibandFilter(conv_trans, options.fps, f0s, wps, options.wr, options.attn_r, options.rppl)
    saveas(fig, filterpath + ".png"); saveas(fig, filterpath + ".fig");
end

function conv_trans = sumKernelsCentered(kernels)
    lengths = cellfun(@length, kernels);
    n = max(lengths);
    conv_trans = zeros(n, 1);
    for i = 1:numel(kernels)
        k = kernels{i};
        pad_left = floor((n - length(k))/2);
        conv_trans(pad_left+1 : pad_left+length(k)) = conv_trans(pad_left+1 : pad_left+length(k)) + k;
    end
end

function options = DefaultOptions(wps)
    options.fps = 1;
    options.wr = wps;
    options.attn_r = 1e5;
    options.attn_l = [];
    options.rppl = 1e-2;

    options.verbose = true;
end
