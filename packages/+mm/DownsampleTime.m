function [Mdownsampled] = DownsampleTime(Mraw,ntaverage)
%     Mdownsampled = zeros( size(Mraw, 1), size(Mraw, 2), floor(size(Mraw, 3)/ ntaverage), class(Mraw) );

    
    if(ntaverage == 1) 
        Mdownsampled = Mraw; return; end

    wasvector = false;
    if(isvector(Mraw)) 
        Mraw = reshape(Mraw,1,1,[]); 
        wasvector = true;
    end

    Mraw = Mraw(:,:, 1:(ntaverage*floor(size(Mraw, 3)/ntaverage)));
    Mdownsampled = cast(...
        squeeze(mean(reshape(...
            Mraw, [size(Mraw, [1,2]), ntaverage, size(Mraw, 3)/ntaverage]), 3)),...
        'like', Mraw);
    
    if(wasvector), Mdownsampled = squeeze(Mdownsampled); end
end

