function [conv_trans] = makeFilterBandpass(filterpath, f0, wp, varargin)

    options = DefaultOptions(wp);
    if(~isempty(varargin))
        options=getOptions(options,varargin);
    end
    if(isempty(options.attn_l)) options.attn_l = options.attn_r; end
    
    if(options.verbose) disp("makeFilterBandpass: Creating filter"); end
    
    designSpecs = fdesign.bandpass('Fst1,Fp1,Fp2,Fst2,Ast1,Ap,Ast2', ...
           (f0-wp-options.wr)*2/options.fps, (f0-wp)*2/options.fps, ...
           (f0+wp)*2/options.fps, (f0+wp+options.wr)*2/options.fps,...
           mag2db(options.attn_l), mag2db(1+options.rppl), mag2db(options.attn_r));
       
    H = design(designSpecs, 'equiripple', 'MinOrder', 'even');
    gd = grpdelay(H); %TODO
    conv_trans = impz(H); %same as cell2mat({H.Numerator}')' for FIR filters 
    
    if(options.verbose) disp("makeFilterBandpass: Filter created"); end
    
    writematrix(conv_trans, filterpath);
    
    fig = plt.getFigureByName('Convolutional Filter Illustration');
    set(gcf, 'Units', 'Normalized', 'OuterPosition', [0.5, 0.5, .4, 0.3])
    plt.ConvolutionalBandpassFilter(conv_trans, options.fps, f0, wp, options.wr, options.attn_r, options.rppl)
    saveas(fig, filterpath + ".png"); saveas(fig, filterpath + ".fig");
end

function options = DefaultOptions(wp)
    options.fps = 1;
    options.wr = wp;
    options.attn_r = 1e5;
    options.attn_l = [];
    options.rppl = 1e-2;

    
    options.verbose = true;
%     options.
    
end
