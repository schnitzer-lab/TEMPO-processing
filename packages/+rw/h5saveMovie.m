function [info_cells] = h5saveMovie(h5filename, movie, movie_specs, movie_dataset)
% h5saveMovie - saves movie array and associated movie_specs to the h5 file
    if(nargin < 4)
        movie_dataset = 'mov';
    end

    info_cells = {h5save(h5filename, movie, movie_dataset), ...
                  rw.h5saveMovieSpecs(h5filename, movie_specs)};
end