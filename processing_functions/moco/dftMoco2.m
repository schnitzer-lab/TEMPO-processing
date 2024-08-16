function [M, shifts,template] = dftMoco2(M,varargin)

    options = defaultOptions(size(M,3));
    if(~isempty(varargin))
        options = getOptions(options, varargin);
    end
    
    %%
%     T = M(:,:,datasample(1:size(M,3), options.template_size,'Replace',false));
    % to reduce memory overhead use median of medians
    if(any(isnan(M),'all')) 
        warning('dftMoco2: movie contains NaNs, replacing with 0s');
        M(isnan(M)) = 0; %needed for dftregistration_min_max(?) & imtranslate
    end

    template = options.spatial_filter(medianOfMedians(M, options.nmedian));
%     template(isnan(template)) = 0;
%     clear('T');
%     if(~options.update_template) clear('T'); end
    
    shifts = NaN([size(M,3),2]);
%     Mf = nan(size(M));
    
%     wb = ParforProgressbar(size(M,3));
%     wb = waitbar(0, 'motion correction ', 'Name','motion correction '); tstart = tic;
    parfor i_f = 1:size(M,3)
        current_frame = options.spatial_filter(M(:,:,i_f));
%         current_frame(isnan(current_frame)) = 0;
        
        output = dftregistration_min_max(fftn(current_frame), fftn(template), ...
            options.upsample, -options.max_shift, options.max_shift, options.phase_flag);
        
        shifts(i_f,:) = output(:,[4,3]);
        
        current_frame_raw = M(:,:,i_f);
        current_frame_raw(isnan(current_frame_raw)) = 0;
        M(:,:,i_f) = imtranslate(current_frame_raw, -shifts(i_f,:), ...
            options.interpolation_method ,'FillValues', options.fill_value);
        
%         if(options.update_template)
%             T(:,:,mod(i_f-1,options.template_size)+1) = ...
%                 imtranslate(current_frame, -shifts(i_f,:), ...
%                     options.interpolation_method ,...
%                     'FillValues', options.fill_value);
%             template = median(T,3,'omitnan');
%             template(isnan(template)) = 0;
%         end
         
%         if(~mod(i_f, 100)) disp(i_f);  end
%         wb.increment();
%    fraction_done = i_f/size(M,3);
%    waitbar(fraction_done, wb, ...
%            sprintf('motion correction (%d minutes left)',...
%            round(toc(tstart)*(1-fraction_done)/fraction_done/60) ));
    end

%     delete(wb);
    %%
end

function options = defaultOptions(nT)
%     options.update_template = false;
    options.nmedian = 2; % subsampling used for median estimation
    options.fill_value = NaN;
    options.interpolation_method = 'cubic';
    options.spatial_filter = @(x) x;
    options.upsample = 20;
    options.max_shift = Inf;
    options.phase_flag = true;
end