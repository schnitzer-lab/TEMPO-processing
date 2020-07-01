function [movie, movie_specs] = h5readMovie(h5filename)
%h5readMovie reads .h5 movie and associated specs

    
    movie_specs = rw.h5readMovieSpecs(h5filename);
    movie = h5read(h5filename, '/movie');
end
