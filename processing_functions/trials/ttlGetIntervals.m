function intervals = ttlGetIntervals(stimulus_value, min_stim_length)
    if(nargin < 2)
        min_stim_length = 0;
    end

    values = sort(unique(stimulus_value));

    if(length(min_stim_length) == 1)
        min_stim_length = repelem(min_stim_length, length(values));
    end

    intervals = {length(values), 1};
    for i_i = 1:length(values)
        intervals{i_i} = NaN(0, 3);
    end



    val_previous = stimulus_value(1);
    counter = 1;
    i_t_start = 1;
    for i_t = 2:length(stimulus_value)
        val = stimulus_value(i_t);

        if(val ~= val_previous && counter >= min_stim_length(values == val_previous))
            val_ind = find(values == val_previous);
            intervals{val_ind} = [intervals{val_ind}; [val_previous, i_t_start, counter] ];
            
            counter = 0;
            i_t_start = i_t;
        end

        counter = counter + 1;
        val_previous = val;
    end
end

