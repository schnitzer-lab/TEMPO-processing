function [info_cells] = h5saveMovie(h5filename, movie, movie_specs)
% h5saveMovie - saves movie array and associated movie_specs to the h5 file

    info_cells = {h5save(h5filename, movie, 'movie'), ...
                  rw.h5saveMovieSpecs(h5filename, movie_specs)};
end