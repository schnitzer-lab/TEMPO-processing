function [image_threshold] = imageDoG(image_in, varargin)
    
    options = DefaultOptions();
    if(~isempty(varargin))
        options=getOptions(options,varargin);
    end

    sd = ceil(options.sdfrac*max(size(image_in)));
    w = 5*sd;% window,st.dev
    gaussian_kernel = fspecial('gaussian', [w w], sd);
    [Gx,Gy] = gradient(gaussian_kernel);

    image_dx = conv2(image_in, Gx, 'same' );
    image_dy = conv2(image_in, Gy, 'same' );

    image_threshold = sqrt(image_dx.^2 + image_dy.^2);

end

%%


function options =  DefaultOptions()
    options.sdfrac = 0.03;
end