classdef MovieSpecs < SimpleHandle & matlab.mixin.Copyable
    %MovieSpecs stores .h5 movie file universal content (besides the movie)
    % and provides simple operations for history manipulations
    %
    % by Vasily
    
    properties (Constant = true)
        history_sep = ';'; %separator of the history string
    end
    
    properties (SetAccess = protected)
        history; % string that contains the history of data processing steps
        history_params; % cell array of structs
        binning; % spatial downsampling factor > 1
        spaceorigin;
        timebinning;
        timeorigin;
        sourcePath;
        
        extra_specs = containers.Map;
    end
    
    properties (SetAccess = private)
        fps; %use getFps function to account for binning
        pixsize; %use getPixSize function to account for binning
     end
    
    methods
        function obj = MovieSpecs(fps, timebinning, timeorigin, ...
                                  pixsize, binning, spaceorigin,...
                                  sourcePath, history, history_params,...
                                  extra_specs)
            if(nargin < 10) extra_specs = containers.Map; end

            [fps, timebinning, timeorigin, pixsize, binning, spaceorigin,...
             sourcePath, history, history_params, extra_specs] = ...
                obj.CheckInputs(fps, timebinning, timeorigin, ...
                                pixsize, binning, spaceorigin,...
                                sourcePath, history, history_params,...
                                extra_specs);


            obj.history = history; %""; %string(history);
            obj.history_params = history_params; 

            obj.fps = fps;
            obj.pixsize = pixsize;
            obj.binning = binning;
            obj.spaceorigin = spaceorigin;
            obj.timebinning = timebinning;
            obj.timeorigin = timeorigin;
            obj.sourcePath = sourcePath;
            
            obj.extra_specs = extra_specs;
        end
        %% core specs interaction      

        function history_array = GetHistory(obj,n)
            if(nargin > 1)
                if(n<0) n = length(obj.history)-abs(n)+1; end % e.g., n=-1 means last
                history_array = obj.history{n};
            else
                history_array = obj.history;
            end

%             history_array = strsplit(obj.history, obj.history_sep);
%             history_array(history_array == "") = [];
%             
%             if(nargin > 1)
%                 n(n < 0) = length(history_array) + 1 + n(n < 0);
%                 history_array = history_array(n);
%             end
        end

        function history_array = AddToHistory(obj,new_entry, params_struct)
            if((isstring(new_entry) || ischar(new_entry)) && nargin < 3) 
                error('function parameters to save not specified') % maybe unnecessarily strict
            end
            if(nargin < 3) params_struct = struct(); end
            if(isstruct(new_entry))
                field_names = fieldnames(new_entry);
                if(numel(field_names) ~= 1) error("new_entry struct should have one entry"); end
                params_struct = new_entry.(field_names{1});
                new_entry = field_names{1};
            end

            if(~isstring(new_entry)&& ~ischar(new_entry))
                error("new_entry for history shoud be string or char")
            end
            if(contains(new_entry, obj.history_sep))
                error("new_entry for history shoud not contain the separator")
            end
            
            obj.history{end+1} = char(new_entry); %obj.history + obj.history_sep + new_entry;
            obj.history_params{end+1} = params_struct;

            history_array = obj.GetHistory();
        end

        function fps = getFps(obj)
            fps = obj.fps/obj.timebinning;
        end

        function timebinning = AddBinningTime(obj,n)
            obj.timebinning = obj.timebinning*n;
            timebinning = obj.timebinning;
        end
        
        function timeorigin = AddFrameDelay(obj, nframes)
            obj.timeorigin = obj.timeorigin + nframes;
            timeorigin = obj.timeorigin;
        end
        
        function pixsize = getPixSize(obj)
            pixsize = obj.pixsize*obj.binning;
        end
        
        function binning = AddBinning(obj,n)
            obj.binning = obj.binning*n;
            binning = obj.binning;
        end    

        function s = getSpaceOrign(obj,dim)
            if(nargin < 2) dim = [1,2]; end
            s = (obj.spaceorigin- [1,1])/obj.binning + [1,1];
            s = s(dim);
        end
        
        function s = AddSpatialCropping(obj,p)
            if(length(p) ~= 2 || any(p < 0) ||  any( floor(p) ~= p) )
                error("spaceorigin should be an array of two round numbers > 0")
            end
            obj.spaceorigin = (obj.spaceorigin) + (p - [1,1])*obj.binning;
            s = obj.getSpaceOrign();
        end
        %% extra_specs interaction
        
        function frange = AddFrequencyRange(obj, f1, f2)
            if(~isKey(obj.extra_specs, 'frange_valid'))
                obj.extra_specs('frange_valid') = [0, obj.fps];
            end

            if(nargin < 3) f2 = []; end
            
            frange = obj.extra_specs('frange_valid');
            if(~isempty(f1)) frange(1) = max(frange(1), f1); end
            if(~isempty(f2)) frange(2) = min(frange(2), f2); end

            obj.extra_specs('frange_valid') = frange;
        end

        function frange = getFrequencyRange(obj, ind)
            if(isKey(obj.extra_specs, 'frange_valid'))
                frange = obj.extra_specs('frange_valid');
            else
                frange = [0, obj.fps];
            end
            if(nargin > 1)
                frange = frange(ind);
            end
        end

        function outlines = getAllenOutlines(obj, outlines_nums)
            if(obj.extra_specs.isKey("allenMapEdgeOutline"))
                raw_outlines = obj.extra_specs("allenMapEdgeOutline");
                if(nargin < 2) outlines_nums = 1:size(raw_outlines, 3); end
                outlines = raw_outlines(:,:,outlines_nums)/obj.binning;
                outlines(:,1,:) = outlines(:,1,:) - obj.getSpaceOrign(2)+1;
                outlines(:,2,:) = outlines(:,2,:) - obj.getSpaceOrign(1)+1;
            else
                warning("No brain regions outlines found");
                outlines = [];
            end
        end
        
        function mask = getMask(obj,movie_size)
            if(nargin < 2) movie_size = []; end

            if(obj.extra_specs.isKey("mask"))
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
            else
                warning("No mask found");
                mask = [];
            end
        end
        
        function mask_nan = getMaskNaN(obj, movie_size)
            if(nargin < 2) movie_size = []; end
            
            mask = obj.getMask(movie_size);
            mask_nan = nan(size(mask));
            mask_nan(logical(mask)) = 1;
        end
        
        function ttl_signal = getTTLTrace(obj, nT)
            if(~obj.extra_specs.isKey('timestamps_table')) 
                ttl_signal = [];
                return;
            end
            timestamps_table = obj.extra_specs('timestamps_table');
            ttl_column = find(string(strsplit(obj.extra_specs('timestamps_table_names'), ';')) == "behavior_ttl");
            ttl_signal = timestamps_table(obj.timeorigin:(obj.timeorigin + nT-1), ttl_column);

%             if(isempty(ttl_signal)) ttl_signal = zeros(nT,1); end
        end       
        %%
        
        function [specs_cells, specs_names] = GetAllSpecs(obj)
            %GetAllSpecs - returs all required specs as two array - cell
            % array of actual specs and sting array of names. For data
            % saving convenience.
            specs_cells = horzcat( ...
                {obj.fps, obj.pixsize, obj.binning, obj.spaceorigin,...
                 obj.timebinning, obj.timeorigin, obj.sourcePath,...
                 strjoin(obj.history, obj.history_sep), ...
                 jsonencode(obj.history_params)}, ...
                obj.extra_specs.values);
            specs_names = ["fps", "pixsize",...
                           "binning", "spaceorigin",...
                           "timebinning",  "timeorigin", "sourcePath",...
                           "history", "history_params", ...
                           "extra_specs/" + string(obj.extra_specs.keys)];
        end
    end
    
    methods(Access = protected)
        function [fps, timebinning, timeorigin, pixsize, binning, spaceorigin,...
             sourcePath, history, history_params, extra_specs] = ...
            CheckInputs(obj, fps, timebinning, timeorigin, ...
                        pixsize, binning, spaceorigin,...
                        sourcePath, history, history_params,...
                        extra_specs)
           
            if(isstring(history)) history = char(history); end
            if(ischar(history)) history = strsplit(history, obj.history_sep); end
            if(ischar(history_params) || isstring(history_params)) 
                history_params = jsondecode(history_params)';
                if(isstruct(history_params)) history_params = {history_params}; end
            end
            
            if(numel(history) > numel(history_params))
                if(numel(history_params) == 0)
                    warning("No history_params entries, padding with empty");
                    for i_h = 1:numel(history)
                        history_params{end+1} = struct('params_not_saved', 1);
                    end
                else
                    error("Unequal number of history entries and history_params");
                end
            end

            if(~isa(extra_specs, 'containers.Map'))
               error("extra_specs must be a containers.Map") 
            end
            
%             if(~ischar(history) && ~isstring(history))
%                 error("history shoud be string or char")
%             end
            
            if(~isnumeric(fps) || fps <= 0 || isinf(fps))
                error("fps %.2f should be a finite number > 0", fps)
            end
            
            if(~isnumeric(pixsize) || pixsize <= 0)
                error("pixsize %d should be a number > 0", pixsize)
            end
            
            if(~isnumeric(binning) || binning < 1)
                error("binning %d should be a number >= 1", binning)
            end
            
            if(length(spaceorigin) ~= 2 || any(spaceorigin < 0) || ...
               any( floor(spaceorigin) ~= spaceorigin) )
                error("spaceorigin should be an array of two round numbers > 0")
            end
            
            if(~isnumeric(timebinning) || timebinning < 1)
                error("timebinning %d should be a number >= 1", timebinning)
            end
            
            if(timeorigin < 0 || floor(timeorigin) ~= timeorigin )
                error("timeorigin %d should be a round number > 0", timeorigin)
            end           
            
            if(~ischar(sourcePath))
                error("sourcePath must be a char array")
            end
        end
        
        function cpObj = copyElement(obj)
            cpObj = copyElement@matlab.mixin.Copyable(obj);
            cpObj.extra_specs = ...
                containers.Map(obj.extra_specs.keys,obj.extra_specs.values);
        end
    end
end

