function [M, shifts, template_out] = dftMoco2(M,varargin)

    options = defaultOptions();
    if(~isempty(varargin))
        options = getOptions(options, varargin);
    end
    %%

    if(any(isnan(M),'all')) 
        warning('dftMoco2: movie contains NaNs, replacing with 0s');
        M(isnan(M)) = 0; %needed for dftregistration_min_max(?) & imtranslate
    end
  
    psize_pre = 0; psize_post = 0;
    if(options.padto2n)
        psize_pre = floor((2.^ceil(log2(size(M, [1,2]))) - size(M, [1,2]))/2);
        psize_post = ceil((2.^ceil(log2(size(M, [1,2]))) - size(M, [1,2]))/2);
    end
    pad_to2n = @(F, v) padarray(padarray(F, psize_pre, v,'pre'), psize_post, v, 'post');
    unpad = @(F) F((psize_pre(1)+1):(size(F,1)-psize_post(1)), (psize_pre(2)+1):(size(F,2)-psize_post(2)));

    z = zeros(size(M, [1,2]) + psize_pre + psize_post);
    z( floor((size(z,1)+1)/2), floor((size(z,2)+1)/2) ) = 1;
    filter = options.spatial_filter(z);     % imagesc(options.spatial_filter(template) -conv2(template, options.spatial_filter(z), 'same'))
    filter_ft = fftn(filter)./fftn(z);

    template = medianOfMedians(M, options.nmedian);
    hann2d = cast(hann(size(M,1))*hann(size(M,2))', class(M));
    % template = options.spatial_filter(template);
    template_ft = filter_ft.*fftn(pad_to2n(template.*hann2d,0));

    % even with windiwing a little different at the edges
    % imshow(options.spatial_filter(template.*hann2d) - ifftn(template_ft), [])
    %%
    
    shifts = NaN([size(M,3),2]);
    Mft = filter_ft.*fft2(pad_to2n(M.*hann2d,0));

    parfor i_f = 1:size(M,3)

        current_frame_ft = Mft(:,:,i_f);
        output = dftregistration( ...
            current_frame_ft, template_ft, options.upsample);
%            -options.max_shift, options.max_shift, options.phase_flag);
        
        shifts(i_f,:) = output(:,[4,3]);
    end

    template_out = unpad(ifftn(template_ft)); 
    %%

    shifts = shifts - median(shifts);

    parfor i_f = 1:size(M,3)
        current_frame_raw = M(:,:,i_f);
        current_frame_raw(isnan(current_frame_raw)) = 0;
        M(:,:,i_f) = imtranslate(current_frame_raw, -shifts(i_f,:), ...
            options.interpolation_method ,'FillValues', options.fill_value);    
    end
    %%
end

function options = defaultOptions()
    options.nmedian = 2; % subsampling used for median estimation
    options.padto2n = true;
    options.fill_value = NaN;
    options.interpolation_method = 'linear';
    options.spatial_filter = @(x) x;
    options.upsample = 8;
    % options.max_shift = Inf;
    % options.phase_flag = true;
end