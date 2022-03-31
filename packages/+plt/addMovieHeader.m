function Mh = addMovieHeader(M, varargin)

    options = defaultOptions(M);
    if(~isempty(varargin))
        options = getOptions(options, varargin);
    end
    %%
    movie_size = size(M);
    
    H = zeros(round(movie_size.*[options.rel_size,1,1]));
    
    if(options.fontsize_title < 0) options.fontsize_title = round(size(H,1)*3/7); end
    if(options.fontsize_fps < 0) options.fontsize_fps = round(size(H,1)/3); end
    %%
    
    h0 = zeros(round(movie_size(1:2).*[options.rel_size,1]));

    h1 = insertText(h0, [size(H,2)*1/2 - strlength(options.title)*options.fontsize_title*0.3, 0], ...
        options.title, 'TextColor', [1,1,1]*options.text_intensity, 'BoxOpacity', 0, 'FontSize', options.fontsize_title);

    %%
    
    for i_f = 1:size(H,3)

        
        frame_text = "frame " + num2str((i_f-1)*options.dframe +1 + options.frame0 -1);

        if(~isempty(options.extra_labels)) frame_text = options.extra_labels(i_f) + " " + frame_text; end
        
        if(options.fps ~= 1)
            frame_text = frame_text + ",   " + num2str(round((i_f-1)/options.fps,2) + " s");
        end

        h2 = insertText(h1, [0, size(H,1)*1/2], frame_text, ...
            'TextColor', [1,1,1]*options.text_intensity, 'BoxOpacity', 0, 'FontSize', options.fontsize_fps);
        hg = rgb2gray(h2);

        H(:,:,i_f) = hg*(options.mmax - options.mmin) + options.mmin;
    end
    %%
    
    Mh = cat(1, H,M);
end

function options = defaultOptions(M)
    
    options.rel_size = 1/6;
    
    options.mmin = min(M(:), [], 'omitnan'); %mean(M(:), 'omitnan');%
    options.mmax = max(M(:), [], 'omitnan');
    
    options.text_intensity = 1;
    
    options.title = "";
    options.fontsize_title = -1;
    options.fontsize_fps = -1;
    
    options.fps = 1;
    options.frame0 = 1;
    options.dframe = 1;
    options.extra_labels = [];
end