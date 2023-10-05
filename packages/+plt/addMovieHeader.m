function Mh = addMovieHeader(M, varargin)

    options = defaultOptions(M);
    if(~isempty(varargin))
        options = getOptions(options, varargin);
    end
    %%
    movie_size = size(M);
    
    H = zeros(round(movie_size.*[options.rel_size,1,1]));
    
    if(options.fontsize_title < 0) options.fontsize_title = round(size(H,1)*3/7)+1; end
    if(options.fontsize_fps < 0) options.fontsize_fps = round(size(H,1)/3)+1; end
    %%
    
    h0 = zeros(round(movie_size(1:2).*[options.rel_size,1]));

    h1 = insertText(h0, [size(H,2)*1/2 - strlength(options.title)*options.fontsize_title*0.3, 0], ...
        options.title, 'TextColor', [1,1,1], 'BoxOpacity', 0, 'FontSize', options.fontsize_title);
    
    %%
    
    for i_f = 1:size(H,3)

        
        frame_text = "frame " + num2str(round((i_f-1)*options.dframe +1 + options.frame0 -1));

        if(~isempty(options.extra_labels)) frame_text = options.extra_labels(i_f) + " " + frame_text; end
        
        if(options.fps ~= 1)
            frame_text = sprintf('%.2f', (i_f-1)*options.dframe/options.fps) + " s" + ",   " + frame_text;
        end

        h2 = insertText(h1, [0, size(H,1)*1/2], frame_text, ...
            'TextColor', [1,1,1], 'BoxOpacity', 0, 'FontSize', options.fontsize_fps);
        hg = imbinarize(rgb2gray(h2));%;

        H(:,:,i_f) = hg*(options.text_value - options.background_value) + options.background_value;
    end
    %%
    
    Mh = cat(1, H,M);
    %%
    
    if(~isempty(options.pxsize))
        ny = round(1/options.pxsize);
        dx = ceil(ny/7/2); dy = dx; %1:7 aspect ratio of a scale bar
        S = repmat(options.background_value, [dx*5, size(M, 2)]);
        S((end-3*dx):(end-dx), dy:min(size(S,2), dy+ny)) = options.text_value;
        % 1mm scalebar in the left lower corner
        Mh = cat(1, Mh, repmat(S, [1,1,size(Mh,3)]));
    end
end

function options = defaultOptions(M)
    
    options.rel_size = 1/6;
    
%     options.mmin = min(M(:), [], 'omitnan'); %mean(M(:), 'omitnan');%
%     options.mmax = max(M(:), [], 'omitnan');
    options.background_value = mean(M(:), 'omitnan');
    options.text_value = -max(abs(M(:)), [], 'omitnan');
    
    options.title = "";
    options.fontsize_title = -1;
    options.fontsize_fps = -1;
    
    options.fps = 1;
    options.frame0 = 1;
    options.dframe = 1;
    options.pxsize = [];
    options.extra_labels = [];
end