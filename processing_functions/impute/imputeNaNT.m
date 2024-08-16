function M = imputeNaNT(M)

    nan_mask = any(isnan(M),3);
    [rows,cols] = find(nan_mask);
    %%
    
    for i_p = 1:length(rows)
        %%
%         i_p = 100;
        y = squeeze(M(rows(i_p), cols(i_p),:));
        x = 1:length(y);

        if(sum(~(isnan(y))) <= 1) continue; end

        y1 = interp1(x(~isnan(y)), y(~isnan(y)), x, 'linear');
        if(any(isnan(y1)))
            y1 = interp1(x(~isnan(y1)), y1(~isnan(y1)), x, 'nearest', 'extrap');
        end
        
        M(rows(i_p), cols(i_p),:) = y1;
        %%
    end

end