function [movie, movie_specs] = h5readMovie(h5filename, dataset)
%h5readMovie reads .h5 movie and associated specs
    if(nargin < 2) dataset = '/mov'; end
    
    movie_specs = rw.h5readMovieSpecs(h5filename);
    movie = h5read(h5filename, dataset);
end
