function [conv_trans] = makeFilterHighpass(filterpath, f0, wp, varargin)

    options = DefaultOptions(wp);
    if(~isempty(varargin))
        options=getOptions(options,varargin);
    end
    
    if(options.verbose) disp("makeFilterHighpass: Creating filter"); end
    
    designSpecs = fdesign.highpass('Fst,Fp,Ast,Ap', ...
           (f0-wp)*2/options.fps, (f0)*2/options.fps, ...
           mag2db(options.attn), mag2db(1+options.rppl) );
       
       
    H = design(designSpecs, 'equiripple', 'MinOrder', 'even'); %TODO: need to investigate more on the matlab filters
    gd = grpdelay(H); %TODO
    conv_trans = impz(H); %same as cell2mat({H.Numerator}')' for FIR filters 
    
    if(options.verbose) disp("makeFilterBandpass: Filter created"); end
    
    writematrix(conv_trans, filterpath);
    
    fig = plt.getFigureByName('Convolutional Filter Illustration');
    set(gcf, 'Units', 'Normalized', 'OuterPosition', [0.5, 0.5, .4, 0.3])
    plt.ConvolutionalBandpassFilter(conv_trans, options.fps, f0, wp, 0, options.attn, options.rppl)
    saveas(fig, filterpath + ".png"); saveas(fig, filterpath + ".fig");
end

function options = DefaultOptions(wp)
    options.fps = 1;
    options.attn = 1e5;
    options.rppl = 1e-2;
    
    options.verbose = true;
%     options.
    
end
