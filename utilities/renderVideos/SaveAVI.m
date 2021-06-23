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
    
    if(options.adjust) M = plt.to01(M, options.quantile); end
    
    v = VideoWriter(path);
    v.FrameRate = options.fps;
    open(v)

    for i=1:size(M, 3) 
        writeVideo(v, M(:,:,i))
        if(~(mod(i-1,100)) && options.verbose)  disp(['Saving AVI, frame ' num2str(i)]); end
    end
    close(v)
    
end

function options =  DefaultOptions()
    options.verbose=true;
    options.overwrite = false;
    
    options.adjust = true;
    options.quantile=1;
    options.fps = 25;  
end
