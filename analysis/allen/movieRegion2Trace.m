function [trace, mask] = movieRegion2Trace(movie,contour,varargin)
%%

    options=defaultOptions(); % add your options below 
    
    if nargin>=3
        options=getOptions(options,varargin(1:end)); % CHECK IF NUMBER OF THE OPTION ARGUMENT OK!
    end
    
    if(options.plot) imshow(std(movie,[],3), []); hold on; end
    
    touse = ~isnan(contour(:,2)) & ~isnan(contour(:,1));
    
    if(options.switchxy)
        cx = contour(touse,2);
        cy = contour(touse,1);
    else
        cx = contour(touse,1);
        cy = contour(touse,2);       
    end
        
    if(options.plot) plot(cx,cy); end
    
    mask = poly2mask(cx,cy, size(movie,1),size(movie,2));
    
    trace=mask2trace(movie,mask)'; % - 2021-06-22 19:34:09 -   RC  
    
    if(options.plot) hold off; end

end  

function options = defaultOptions()
    options.switchxy = true;
    options.plot = false;
end