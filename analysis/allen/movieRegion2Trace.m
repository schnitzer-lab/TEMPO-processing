function [trace, mask] = movieRegion2Trace(movie,contours,varargin)
%%

    options=defaultOptions(); % add your options below 
    
    if nargin>=3
        options=getOptions(options,varargin(1:end)); % CHECK IF NUMBER OF THE OPTION ARGUMENT OK!
    end
    
    if(isempty(options.m2d)) options.m2d = std(movie,[],3); end
    
    if(options.plot) 
        im = imshow(options.m2d, []); hold on; 
        set(im, 'AlphaData', ~isnan(options.m2d) );
    end
    if(~iscell(contours)) contours = {contours}; end

    mask = zeros(size(movie,[1,2]));
    for i_c = 1:length(contours)

        contour = contours{i_c};
        touse = ~isnan(contour(:,2)) & ~isnan(contour(:,1));
        
        if(options.switchxy)
            cx = contour(touse,2);
            cy = contour(touse,1);
        else
            cx = contour(touse,1);
            cy = contour(touse,2);       
        end
            
        if(options.plot) plot(cx,cy); end
        
        mask = mask | poly2mask(cx,cy, size(movie,1),size(movie,2));
    end

    trace=mask2trace(movie,mask)'; % - 2021-06-22 19:34:09 -   RC  
    
    if(options.plot) hold off; end

end  

function options = defaultOptions()
    options.switchxy = true;
    options.plot = false;
    options.m2d = [];
end