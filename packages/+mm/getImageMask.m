function [mask, array_edge_inv] = getImageMask(array_in, varargin)
    
    options = DefaultOptions();
    if(~isempty(varargin))
        options=getOptions(options,varargin);
    end

    array_edge = mm.imageDoG(array_in, 'sdfrac', options.dog_sdfrac);
    array_edge_inv =  1./(array_edge + quantile(array_edge(:), options.edgeq0 ));
%     imshow(Medge.*array_in,[] )

    Mref =array_edge_inv.*array_in;
    q = mean(Mref(:))*options.thres;
    
    smooth_sd = ceil(min(size(array_in))*options.sm_sdfrac/2)*2-1;
    mask = round(imgaussfilt(double((Mref > q)),'FilterSize', smooth_sd) > 0);
end

function options = DefaultOptions()
    options.thres = 0.3;

    options.dog_sdfrac = 0.005;
    options.sm_sdfrac = 0.02;
    
    options.edgeq0 = 0.5;
end