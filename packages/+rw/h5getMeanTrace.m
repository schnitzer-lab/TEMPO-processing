function movie_mean = h5getMeanTrace(h5filename, varargin)
   
    options = defaultOptions();
    if(~isempty(varargin))
        options = getOptions(options, varargin);
    end

    movie_size = rw.h5getDatasetSize(h5filename, options.dataset);
    specs = rw.h5readMovieSpecs(h5filename);
    nan_mask = double(specs.getMask()); nan_mask(nan_mask==0) = NaN;

    movie_total = zeros([movie_size(3), 1]);
    movie_current = [];
   
    for i_c = 1:options.nframes_read:movie_size(3)
%         disp(i_c);
        nframes_read = min(options.nframes_read, movie_size(3)-i_c+1);

        movie_current = h5read(h5filename, options.dataset, [1, 1, i_c], [Inf, Inf, nframes_read]);

        if(~isempty(nan_mask))
            movie_current = movie_current.*nan_mask; %(:,i_c:(i_c+nrows_read-1));
        end

        movie_total(i_c:(i_c+nframes_read-1)) = sum(movie_current, [1,2], 'omitnan');
    end

%     xy_size = prod(movie_size(1:2));
%     if(~isempty(nan_mask)) xy_size = sum(~isnan(nan_mask), 'all'); end

    movie_mean = movie_total;
end


function options = defaultOptions()
    
    options.dataset = '/mov';
    options.nframes_read = Inf;
end