function [] = SaveAVI(M, path, varargin)
% Saves 3d movie array as .avi file
% by Vasily

    options = DefaultOptions();
    if nargin>=3
        options=getOptions(options,varargin);
    end
    
    if (isfile(path)) 
        if( options.overwrite )
            warning("output file " + path + " already exists, deleting first"); 
            delete(path);
        else
            warning("output file " + path + " already exists, existing SaveAVI"); 
            return;
        end    
    end
    
    if(options.saturate) M = plt.saturate(M, options.saturate); end
    
    v = VideoWriter(char(path), 'Indexed AVI');
    
    M(isnan(M)) = options.nanvalue;
    M = round(plt.to01(M)*(2^8-1));
    
    v.FrameRate = options.fps;
    v.Colormap = options.colormap;
    open(v)

    for i=1:size(M, 3) 
        writeVideo(v, M(:,:,i))
        if(~(mod(i-1,100)) && options.verbose)  disp(['Saving AVI, frame ' num2str(i)]); end
    end
    close(v)
    
end

function options =  DefaultOptions()
    options.verbose=false;
    options.overwrite = false;
    options.colormap = gray;
    options.nanvalue = 0;
    
    options.adjust = true;
    options.saturate=0;
    options.fps = 25;  
end
