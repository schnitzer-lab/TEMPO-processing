function movie_mean = h5getMeanTrace(h5filename, varargin)
   
    options = defaultOptions();
    if(~isempty(varargin))
        options = getOptions(options, varargin);
    end

    movie_size = rw.h5getDatasetSize(h5filename, options.dataset);

    movie_total = zeros([movie_size(3), 1]);
    movie_current = [];
   
    for i_c = 1:options.ncols_read:movie_size(2)
        ncols_read = min(options.ncols_read, movie_size(2) - i_c+ 1);

        movie_current = h5read(h5filename, options.dataset, [1, i_c, 1], [Inf, ncols_read, Inf]);
        movie_total = movie_total + squeeze(sum(movie_current, [1,2], 'omitnan'));
    end

    movie_mean = movie_total / prod(movie_size(1:2));
end


function options = defaultOptions()
    
    options.dataset = '/mov';
    options.ncols_read = Inf;
end