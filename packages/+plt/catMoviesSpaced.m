function Mfull = catMoviesSpaced(Ms, axis, varargin)
    
    options = defaultOptions();
    if(~isempty(varargin))
        options = getOptions(options, varargin);
    end
    
    % options.spacer_size = round(options.sapacer_size_rel*size(Ms{1}, axis));

    if(options.spacer_size < 0)
        spacer_sizes_rel = ones(1, ndims(Ms{1}));
        spacer_sizes_rel(axis) = options.sapacer_size_rel ;
        spacer_sizes = round(size(Ms{1}).*spacer_sizes_rel);
    else
        spacer_sizes = size(Ms{1});
        spacer_sizes(axis) = options.spacer_size;
    end

    spacer = repmat(options.value, spacer_sizes);

    Mfull = [];

    for i_m = 1:length(Ms)

        Mfull = cat(axis, Mfull, Ms{i_m});
        if(i_m ~= length(Ms))
            Mfull = cat(axis, Mfull, spacer);
        end
    end
end

function options = defaultOptions()
    options.value = 0;
    options.sapacer_size_rel = 0.1;
    
    options.spacer_size = -1;
end
