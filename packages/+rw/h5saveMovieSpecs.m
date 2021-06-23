function [info_cells] = h5saveMovieSpecs(h5filename, movie_specs, specspath)
% h5saveMovieSpecs - saves movie specs (inputed as MovieSpecs class object) to the h5 file
    if(nargin < 3)
        specspath = '/specs';
    end

    [specs_cells, specs_names] = movie_specs.GetAllSpecs();
    
    info_cells = cell(length(specs_cells),1);
    
    for i = 1:length(specs_cells) 
        %info_cells{i+1} = ...
            rw.h5writeStruct(h5filename, specs_cells{i}, [specspath, '/', char(specs_names(i))]);
    end
end

