function [] = SaveAVI(M, path, varargin)
% Saves 3d movie array as .avi file
% by Vasily

    options = DefaultOptions();
    if nargin>=3
        options=getOptions(options,varargin);
    end
    
    if (exist([path '.avi'], 'file') == 2) 
        error("output file " + path + " already exists"); 
    end
    
    if(options.adjust) M = plt.to01(M, options.quantile); end
    
    v = VideoWriter(path);
    v.FrameRate = options.fps;
    open(v)

    for i=1:size(M, 3) 
        writeVideo(v, M(:,:,i))
        if(~(mod(i,100)) && options.verbose)  disp(i); end
    end
    close(v)
end

function options =  DefaultOptions()
    options.verbose=true;
    
    options.adjust = true;
    options.quantile=1;
    options.fps = 25;  
end
