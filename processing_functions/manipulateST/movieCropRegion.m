function fullpath_out = movieCropRegion(fullpath_movie, region_ids, varargin)
% MOVIECROPREGION Crop a movie to the bounding box of an Allen-atlas region (or region group).
%   fullpath_out = MOVIECROPREGION(fullpath_movie, region_id, ...) resolves
%   region_id (a region name/array of names, or Allen index/indices, treated
%   as a single combined ROI) to its Allen-atlas outline(s), computes the
%   tight bounding box around their union, and crops the movie to that box
%   via movieCrop.
%
%   Inputs:
%       fullpath_movie - path to the input movie (.h5)
%       regions_id      - region name(s) (resolved via options.regions_map)
%                        or Allen outline index/indices, forming one ROI
%       varargin       - name-value options, see below
%
%   Options:
%       regions_map  - containers.Map from region name to Allen index
%                      (default: getAllenRegionMap())
%       mask         - if true, also intersect the region outline with the
%                      movie's spatial mask (specs.getMask), so the crop
%                      box tightly bounds only the unmasked part of the
%                      selected region instead of the whole region outline
%                      (default: true)
%       postfix_new 
%       outdir      
%       diagnosticdir
%       skip         
%
%   Output:
%       fullpath_out - path to the saved, cropped movie (see movieCrop)


    [basepath, ~, ~] = fileparts(fullpath_movie);
    options = parseInputs(basepath, region_ids, varargin{:});
    %%

    if(isstring(region_ids) || ischar(region_ids))
        region_ids = string(region_ids);
        if(any(~arrayfun(@(r) options.regions_map.isKey(r), region_ids)))
            error("movieCropRegion: region name not found: " + strjoin(region_ids, ','))
        end
        region_ids = cell2mat(arrayfun(@(r) options.regions_map(r), region_ids, 'UniformOutput', false));
    end
    %%

    specs = rw.h5readMovieSpecs(fullpath_movie);
    if(isempty(specs.getAllenOutlines()))
        error("movieCropRegion: no allen outlines found: " + fullpath_movie)
    end

    [Nx, Ny] = rw.h5getDatasetSize(fullpath_movie, '/mov', [1,2]);
    %%

    contours = cell(length(region_ids),1);
    for i_c = 1:length(region_ids)
        contours{i_c} = specs.getAllenOutlines(region_ids(i_c));
    end
    if(isempty(contours{1}))
        error("movieCropRegion: no region " + strjoin(string(region_ids),"+") + " found")
    end

    [~, mask] = movieRegion2Trace(zeros(Nx,Ny), contours, 'switchxy', false);
    %%

    if(options.mask)
        movie_mask = specs.getMask([Nx, Ny]);
        if(~isempty(movie_mask))
            mask = mask & movie_mask;
            if(~any(mask(:)))
                error("movieCropRegion: no unmasked pixels found within region " + strjoin(string(region_ids),"+"))
            end
        end
    end
    %%

    [rows, cols] = find(mask);
    box_crop = [min(cols), min(rows), max(cols)-min(cols)+1, max(rows)-min(rows)+1];
    %%

    fullpath_out = movieCrop(fullpath_movie, box_crop, ...
        'outdir', options.outdir, ...
        'postfix_new', options.postfix_new, ...
        'skip', options.skip, ...
        'diagnosticdir', options.diagnosticdir);
end
%%

function options = parseInputs(basepath, region_ids, varargin)

    p = inputParser();

    p.addParameter('regions_map', getAllenRegionMap());
    p.addParameter('mask', true, @(x) islogical(x) || isnumeric(x));

    p.addParameter('postfix_new', "_crop" + strjoin(string(region_ids), '+'), @(s) isstring(s)|ischar(s));

    p.addParameter('outdir', basepath, @(s) isstring(s)|ischar(s));
    p.addParameter('diagnosticdir', basepath + "\diagnostic\movieCropRegion\", @(s) isstring(s)|ischar(s));
    p.addParameter('skip', true, @(x) (x==true)|(x==false));

    p.parse(varargin{:});
    options = p.Results;
end
%%
