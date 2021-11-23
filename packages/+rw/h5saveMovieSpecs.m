function [info_cells] = h5saveMovieSpecs(h5filename, movie_specs, varargin)
% h5saveMovieSpecs - saves movie specs (inputed as MovieSpecs class object) to the h5 file

    options = defaultOptions();
    if(~isempty(varargin))
        options = getOptions(options, varargin);
    end


    [specs_cells, specs_names] = movie_specs.GetAllSpecs();
    
    info_cells = cell(length(specs_cells),1);
    
    dataset_extra =  [options.specspath, '/', 'extra_specs'];
    if(~rw.h5checkDatasetExists(h5filename, dataset_extra))
        rw.h5writeStruct(h5filename, [0], [dataset_extra, '/empty_spec'])
    end
    
    for i = 1:length(specs_cells)
        dataset_spec = [options.specspath, '/', char(specs_names(i))];
        if(~options.rewrite)
            if(rw.h5checkDatasetExists(h5filename, dataset_spec)) continue; end
        end
        %info_cells{i+1} = ...
            rw.h5writeStruct(h5filename, specs_cells{i}, dataset_spec);
    end
end

function options = defaultOptions()
    options.specspath = '/specs';
    options.rewrite = true;
end