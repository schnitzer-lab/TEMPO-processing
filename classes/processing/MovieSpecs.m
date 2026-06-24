classdef MovieSpecs < handle & matlab.mixin.Copyable
    %MovieSpecs stores .h5 movie file universal content (besides the movie)
    % and provides simple operations for history manipulations
    %
    % by Vasily
        
    properties (SetAccess = private)
        mouse_id;
        recording_id;
        channel_id;
    end
    
    properties (SetAccess = private, GetAccess = protected)
        fps; %TODO: rename fps0, use getFps and AddBinningTime
        pixsize; %TODO: rename pixsize0, use getPixSize and AddBinning
    end
    
    properties(SetAccess = protected, Hidden = true)
        binning; % spatial downsampling factor, use AddBinning
        spaceorigin;
        timebinning;
        timeorigin; 

        sourcePath; % TODO: fix older naming convention for sourcePath

        history; % cell array of strings - history of data processing steps
        history_params; % cell array of structs
  
        extra_specs; %containers.Map;
    end

    properties (Constant = true, Hidden = true)
        history_sep = ';'; %separator of the history string when saved
    end
    
    methods
          function obj = MovieSpecs(fps, timebinning, timeorigin, ...
                                  pixsize, binning, spaceorigin,...
                                  mouse_id, recording_id, channel_id,...
                                  source_path, history, history_params,...
                                  extra_specs)
            if(nargin < 13), extra_specs = containers.Map; end

            [fps, timebinning, timeorigin, pixsize, binning, spaceorigin,...
             source_path, history, history_params, extra_specs] = ...
                obj.CheckInputs(fps, timebinning, timeorigin, ...
                                pixsize, binning, spaceorigin,...
                                .... % mouse_id, recording_id, channel_id,...
                                source_path, history, history_params,...
                                extra_specs);


            obj.history = history; %""; %string(history);
            obj.history_params = history_params; 

            obj.fps = fps;
            obj.pixsize = pixsize;
            
            obj.binning = binning;
            obj.spaceorigin = spaceorigin;
            obj.timebinning = timebinning;
            obj.timeorigin = timeorigin;
            
            obj.mouse_id = mouse_id;
            obj.recording_id = recording_id;
            obj.channel_id = channel_id;

            obj.sourcePath = source_path;
                       
            obj.extra_specs = extra_specs;
        end
    end

    %% getter methods
    
    methods
        function [history, history_params] = GetHistory(obj,n)
            if(nargin > 1)
                if(n<0), n = length(obj.history)-abs(n)+1; end % e.g., n=-1 means last
                history = obj.history{n};
                history_params = obj.history_params{n};
            else
                history = obj.history';
                history_params = obj.history_params';
            end
        end
    
        function fps = getFps(obj)
            fps = obj.fps/obj.timebinning;
        end

        function pixsize = getPixSize(obj)
            pixsize = obj.pixsize*obj.binning;
        end

        function s = getSpaceOrign(obj,dim)
            if(nargin < 2), dim = [1,2]; end
            s = (obj.spaceorigin- [1,1])/obj.binning + [1,1];
            s = s(dim);
        end
    end
    %% setter methods

    methods
       %% core specs interaction      

        function history_array = AddToHistory(obj,new_entry, params_struct)
            if((isstring(new_entry) || ischar(new_entry)) && nargin < 3) 
                error('function parameters to save not specified') % maybe unnecessarily strict
            end
            if(nargin < 3), params_struct = struct(); end
            if(isstruct(new_entry))
                field_names = fieldnames(new_entry);
                if(numel(field_names) ~= 1), error("new_entry struct should have one entry"); end
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

        function timebinning = AddBinningTime(obj,n)
            obj.timebinning = obj.timebinning*n;
            timebinning = obj.timebinning;
        end
        
        function timeorigin = AddFrameDelay(obj, nframes)
            obj.timeorigin = obj.timeorigin + nframes;
            timeorigin = obj.timeorigin;
        end
      
        function binning = AddBinning(obj,n)
            obj.binning = obj.binning*n;
            binning = obj.binning;
        end    
        
        function s = AddSpatialCropping(obj,p)
            if(length(p) ~= 2 || any(p < 0) ||  any( floor(p) ~= p) )
                error("spaceorigin should be an array of two round numbers > 0")
            end
            obj.spaceorigin = (obj.spaceorigin) + round((p - [1,1])*obj.binning);
            s = obj.getSpaceOrign();
        end

    end

    methods (Hidden = true)
        % For saving only        
        function [specs_cells, specs_names] = GetAllSpecs(obj)
            %GetAllSpecs - returs all required specs as two array - cell
            % array of actual specs and sting array of names. For data
            % saving convenience.
            specs_cells = horzcat( ...
                {obj.fps, obj.pixsize, obj.binning, obj.spaceorigin,...
                 obj.timebinning, obj.timeorigin, obj.sourcePath,...
                 obj.mouse_id, obj.recording_id, obj.channel_id,...
                 strjoin(obj.history, obj.history_sep), jsonencode(obj.history_params)}, ...
                obj.extra_specs.values);
            specs_names = ["fps", "pixsize",...
                           "binning", "spaceorigin",...
                           "timebinning",  "timeorigin", "sourcePath",...
                           "mouse_id", "recording_id", "channel_id",...
                           "history", "history_params", ...
                           "extra_specs/" + string(obj.extra_specs.keys)];
        end
    end
    
    methods(Access = protected)
        function [fps, timebinning, timeorigin, pixsize, binning, spaceorigin,...
             source_path, history, history_params, extra_specs] = ...
            CheckInputs(obj, fps, timebinning, timeorigin, ...
                        pixsize, binning, spaceorigin,...
                        source_path, history, history_params,...
                        extra_specs)
           
            if(isstring(history)), history = char(history); end
            if(ischar(history)), history = strsplit(history, obj.history_sep); end
            if(ischar(history_params) || isstring(history_params)) 
                history_params = jsondecode(history_params)';
                if(isstruct(history_params)), history_params = {history_params}; end
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
            
            if(~isnumeric(binning))
                error("binning %d should be a number", binning)
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
            
            if(~ischar(source_path))
                error("source_path must be a char array")
            end
        end
        
        function cpObj = copyElement(obj)
            cpObj = copyElement@matlab.mixin.Copyable(obj);
            cpObj.extra_specs = ...
                containers.Map(obj.extra_specs.keys,obj.extra_specs.values);
        end
    end
end

