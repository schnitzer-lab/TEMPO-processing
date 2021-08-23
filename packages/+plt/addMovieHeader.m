function Mh = addMovieHeader(M, varargin)

    options = defaultOptions(M);
    if(~isempty(varargin))
        options = getOptions(options, varargin);
    end
    %%
    movie_size = size(M);
    
    H = zeros(round(movie_size.*[options.rel_size,1,1]));
    
    fontsize_title = round(size(H,1)*3/7);
    fontsize_fps = round(size(H,1)/3);
    %%
    
    h0 = zeros(round(movie_size(1:2).*[options.rel_size,1]));

    h1 = insertText(h0, [size(H,2)*1/2 - length(options.title)*fontsize_title/3, 0], ...
        options.title, 'TextColor', 'white', 'BoxOpacity', 0, 'FontSize', fontsize_title);

    %%
    
    for i_f = 1:size(H,3)

        frame_text = "frame " + num2str(i_f + options.frame0 -1);

        if(options.fps ~= 1)
            frame_text = frame_text + ",   " + num2str(round((i_f-1)/options.fps,2) + " s");
        end

        h2 = insertText(h1, [0, size(H,1)*1/2], frame_text, 'TextColor', 'white', 'BoxOpacity', 0, 'FontSize', fontsize_fps);
        hg = rgb2gray(h2);

        H(:,:,i_f) = hg*(options.mmax - options.mmin) + options.mmin;
    end
    %%
    
    Mh = cat(1, H,M);
end

function options = defaultOptions(M)
    
    options.rel_size = 1/6;
    
    options.mmin = mean(M(:), 'omitnan');
    options.mmax = max(M(:));
    
    options.title = "";
    
    options.fps = 1;
    options.frame0 = 1;
end