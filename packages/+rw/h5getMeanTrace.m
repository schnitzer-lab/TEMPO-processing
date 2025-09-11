function movie_mean = h5getMeanTrace(h5filename, varargin)
   
    options = defaultOptions();
    if(~isempty(varargin))
        options = getOptions(options, varargin);
    end

    nt = rw.h5getDatasetSize(h5filename, options.dataset, 3);
    specs = rw.h5readMovieSpecs(h5filename);

    movie_total = nan([nt, 1]);
    movie_current = [];
   
    for i_c = 1:options.nframes_read:nt
        nframes_read = min(options.nframes_read, nt-i_c+1);

        movie_current = h5read(h5filename, options.dataset, [1, 1, i_c], [Inf, Inf, nframes_read]);

        if(~isempty(specs.getMaskNaN()))
            movie_current = movie_current.*specs.getMaskNaN(); %(:,i_c:(i_c+nrows_read-1));
        end

        movie_total(i_c:(i_c+nframes_read-1)) = mean(movie_current, [1,2], 'omitnan');
    end

    movie_mean = cast(movie_total, 'like', mean(movie_current, [1,2], 'omitnan'));
end


function options = defaultOptions()
    
    options.dataset = '/mov';
    options.nframes_read = Inf;
end