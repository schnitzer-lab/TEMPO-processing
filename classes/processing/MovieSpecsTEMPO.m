classdef MovieSpecsTEMPO < MovieSpecs
    %MovieSpecs stores .h5 movie file universal content (besides the movie)
    % and provides simple operations for history manipulations
    %
    % by Vasily
        
   
    methods
        % extra_specs interaction
        
        function frange = AddFrequencyRange(obj, f1, f2)
            if(~isKey(obj.extra_specs, 'frange_valid'))
                obj.extra_specs('frange_valid') = [0, obj.fps/2];
            end

            if(nargin < 3), f2 = []; end
            
            frange = obj.extra_specs('frange_valid');
            if(~isempty(f1)), frange(1) = max(frange(1), f1); end
            if(~isempty(f2)), frange(2) = min(frange(2), f2); end

            obj.extra_specs('frange_valid') = frange;
        end

        function frange = getFrequencyRange(obj, ind)
            if(isKey(obj.extra_specs, 'frange_valid'))
                frange = obj.extra_specs('frange_valid');
            else
                frange = [0, obj.fps/2];
            end
            if(nargin > 1)
                frange = frange(ind);
            end
        end

        function outlines = getAllenOutlines(obj, outlines_nums)
            if(obj.extra_specs.isKey("allenMapEdgeOutline"))
                raw_outlines = obj.extra_specs("allenMapEdgeOutline");
                if(nargin < 2), outlines_nums = 1:size(raw_outlines, 3); end
                outlines = raw_outlines(:,:,outlines_nums)/obj.binning;
                outlines(:,1,:) = outlines(:,1,:)-obj.getSpaceOrign(2)+1;
                outlines(:,2,:) = outlines(:,2,:)-obj.getSpaceOrign(1)+1;
            else
                warning("No brain regions outlines found");
                outlines = [];
            end
        end

        function outlines = getCustomOutlines(obj, outlines_nums)
            if(obj.extra_specs.isKey("customOutlines"))
                raw_outlines = obj.extra_specs("customOutlines");
                if(nargin < 2), outlines_nums = 1:size(raw_outlines, 3); end
                outlines = raw_outlines(:,:,outlines_nums)/obj.binning;
                outlines(:,1,:) = outlines(:,1,:)-obj.getSpaceOrign(2)+1;
                outlines(:,2,:) = outlines(:,2,:)-obj.getSpaceOrign(1)+1;
            else
                warning("No custom brain outlines found");
                outlines = [];
            end
        end
        
        function mask = getMask(obj,movie_size)
            if(nargin < 2), movie_size = []; end

            if(~obj.extra_specs.isKey("mask")) 
                % warning("No mask found");
                mask = [];
            elseif(isinf(obj.binning)), mask = [];
            else
                raw_mask = obj.extra_specs("mask");
                mask = imresize(raw_mask, 1/obj.binning, 'bilinear');
                size_out = floor(size(raw_mask)/obj.binning);
                mask = round(mask(1:size_out(1),1:size_out(2)));
                mask = mask(obj.getSpaceOrign(1):end, ...
                            obj.getSpaceOrign(2):end);
                if(~isempty(movie_size)) 
                    mask = mask(1:(movie_size(1)), ...
                                1:(movie_size(2)));
                end
            end
            mask = logical(mask);
        end
        
        function mask_nan = getMaskNaN(obj, movie_size)
            if(nargin < 2), movie_size = []; end
            
            mask = obj.getMask(movie_size);
            mask_nan = nan(size(mask));
            mask_nan(mask) = 1;
        end
        
        function ttl_signal = getTTLTraceFromanalog(obj, nT)
            if(~obj.extra_specs.isKey('ttl_fromanalog')) 
                ttl_signal = [];
                return;
            end
            if(nargin < 2), nT = length(obj.extra_specs('ttl_fromanalog'))-(obj.timeorigin-1); end
            
            ttl_signal_full = obj.extra_specs('ttl_fromanalog');
            ttl_signal_raw = ttl_signal_full(obj.timeorigin:end);
            
            ttl_signal = ttl_signal_raw;
            if(obj.timebinning ~= 1)
                ttl_signal = ttl_signal(1:(length(ttl_signal) - mod(length(ttl_signal), obj.timebinning)));
                ttl_signal = round(mean(reshape(ttl_signal,obj.timebinning,[]),1)');
            end
            ttl_signal = ttl_signal(1:min(nT, length(ttl_signal)));
            ttl_signal((end+1):nT) = NaN;
        end   

        function ttl_signal = getTTLTrace(obj, nT)
            if(~obj.extra_specs.isKey('timestamps_table')) 
                ttl_signal = [];
                return;
            end
            
            timestamps_table = obj.extra_specs('timestamps_table');

            if(nargin < 2), nT = size(timestamps_table,1)-(obj.timeorigin-1); end

            ttl_column = find(string(strsplit(obj.extra_specs('timestamps_table_names'), ';')) == "behavior_ttl");
            
            ttl_signal_raw = timestamps_table(obj.timeorigin:end, ttl_column);
            
            ttl_signal = ttl_signal_raw;
            if(obj.timebinning ~= 1)
                ttl_signal = ttl_signal(1:(length(ttl_signal) - mod(length(ttl_signal), obj.timebinning)));
                ttl_signal = round(mean(reshape(ttl_signal,obj.timebinning,[]),1)');
            end
            ttl_signal = ttl_signal(1:min(nT, length(ttl_signal)));
            ttl_signal((end+1):nT) = NaN;
        end   
        %%   
    end
end
