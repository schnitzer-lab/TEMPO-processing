function [info_cells] = h5saveMovieSpecs(h5filename, movie_specs)
% h5saveMovieSpecs - saves movie specs (inputed as MovieSpecs class object) to the h5 file

    [specs_cells, specs_names] = movie_specs.GetAllSpecs();
    
    info_cells = cell(length(specs_cells),1);
    
    for i = 1:length(specs_cells) 
        info_cells{i+1} = ...
            h5save(h5filename, specs_cells{i}, char(specs_names(i)));
    end
end

