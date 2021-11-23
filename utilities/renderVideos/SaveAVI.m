function [] = SaveAVI(M, path, varargin)
% Saves 3d movie array as .avi file
% by Vasily

    options = DefaultOptions();
    if nargin>=3
        options=getOptions(options,varargin);
    end
    
    if (exist([path '.avi'], 'file') == 2) 
        if( options.overwrite )
            warning("output file " + path + " already exists, deleting first"); 
            delete([path '.avi']);
        else
            warning("output file " + path + " already exists, existing SaveAVI"); 
            return;
        end    
    end
    
    if(options.saturate) M = plt.saturate(M, options.saturate); end
    
    v = VideoWriter(path, 'Indexed AVI');
    
    M = plt.to01(M);
    M = round(M/max(M(:), [], 'omitnan')*(2^8-1));
    M(isnan(M)) = options.nanvalue;
    
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
