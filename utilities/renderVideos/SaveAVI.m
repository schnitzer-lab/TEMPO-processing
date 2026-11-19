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
    
    % pixels equal to +Inf are drawn in textcolor (excluded from scaling)
    textmask = false(size(M));
    if(~isempty(options.textcolor))
        textmask = (M == Inf);
        M(textmask) = NaN;
    end

    if(options.saturate), M = plt.saturate(M, options.saturate); end

    v = VideoWriter(char(path), 'Indexed AVI');

    nanmask = isnan(M) & ~textmask;
    cmap = options.colormap;

    if(isempty(options.nancolor) && isempty(options.textcolor))
        M(nanmask) = options.nanvalue;
        M = round(plt.to01(M)*(2^8-1));
    else
        % special colors take the last colormap entries: textcolor, nancolor
        extra = [reshape(options.textcolor, [], 3); ...
                 reshape(options.nancolor, [], 3)];
        n_data = 2^8 - size(extra, 1);

        if(isempty(options.nancolor)), M(nanmask) = options.nanvalue; end
        M = round(plt.to01(M)*(n_data-1)); % text pixels are nan: unscaled

        i_extra = n_data;
        if(~isempty(options.textcolor))
            M(textmask) = i_extra; i_extra = i_extra+1;
        end
        if(~isempty(options.nancolor)), M(nanmask) = i_extra; end

        M = uint8(M); % uint8 indices are 0-based, doubles are 1-based
        cmap = interp1(linspace(0, 1, size(cmap, 1)), cmap, ...
            linspace(0, 1, n_data));
        cmap = [cmap; extra];
    end

    v.FrameRate = options.fps;
    v.Colormap = cmap;
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
    options.nancolor = []; % rgb triplet in 0-1, overrides nanvalue if set
    options.textcolor = []; % rgb triplet in 0-1 for pixels equal to +Inf

    options.adjust = true;
    options.saturate=0;
    options.fps = 25;  
end
