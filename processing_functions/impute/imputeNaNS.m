
function M = imputeNaNS(M)

    frame_ids = find(squeeze(any(isnan(M),[1,2])));
    %%
    
    for i_f = frame_ids'
        %%

        current_frame_raw = M(:,:,i_f);
        M(:,:,i_f) = cast(inpaint_nans(double(current_frame_raw)), "like", current_frame_raw);
        %%
    end

end