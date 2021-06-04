classdef MovieSpecs < SimpleHandle
    %MovieSpecs stores .h5 movie file universal content (besides the movie)
    % and provides simple operations for history manipulations
    %
    % by Vasily
    
    properties (Constant = true)
        history_sep = ';'; %separator of the history string
    end
    
    properties (SetAccess = protected)
        history; % string that contains the history of data processing steps
        fps;
        pixsize; % spatial downsampling factor \in [0,1]
        binning;
        spaceorigin;
        timebinning;
        timeorigin;
        sourcePath;
        
        extra_specs = containers.Map;
    end
    
    methods
        function obj = MovieSpecs(history, fps, pixsize,...
                                  binning, spaceorigin,...
                                  timebinning, timeorigin, ...
                                  sourcePath, extra_specs)
            if(nargin < 9) extra_specs = containers.Map; end
            
            obj.CheckInputs(history, fps, pixsize,...
                            binning, spaceorigin,...
                            timebinning, timeorigin, sourcePath, extra_specs);
            
            obj.history = string(history);
            obj.fps = fps;
            obj.pixsize = pixsize;
            obj.binning = binning;
            obj.spaceorigin = spaceorigin;
            obj.timebinning = timebinning;
            obj.timeorigin = timeorigin;
            obj.sourcePath = sourcePath;
            
            obj.extra_specs = extra_specs;
        end
        
        function history_array = AddToHistory(obj,new_entry)
            if(~isstring(new_entry)&& ~ischar(new_entry))
                error("new_entry for history shoud be string or char")
            end
            if(contains(new_entry, obj.history_sep))
                error("new_entry for history shoud not contain the separator")
            end
            
            obj.history  = obj.history + obj.history_sep + new_entry;
            history_array = obj.GetHistory();
        end
        
        function history_array = GetHistory(obj,n)
            history_array = strsplit(obj.history, obj.history_sep);
            history_array(history_array == "") = [];
            
            if(nargin > 1)
                n(n < 0) = length(history_array) + 1 + n(n < 0);
                history_array = history_array(n);
            end
        end
        
        function [specs_cells, specs_names] = GetAllSpecs(obj)
            %GetAllSpecs - returs all required specs as two array - cell
            % array of actual specs and sting array of names. For data
            % saving convenience.
            specs_cells = horzcat({obj.history, obj.fps, obj.pixsize,... 
                                   obj.binning, obj.spaceorigin,...
                                   obj.timebinning, obj.timeorigin, obj.sourcePath}, ...
                                   obj.extra_specs.values);
            specs_names = ["history", "fps", "pixsize",...
                           "binning", "spaceorigin",...
                           "timebinning",  "timeorigin", "sourcePath", ...
                           string(obj.extra_specs.keys)];
        end
    end
    
    methods(Access = protected)
        function CheckInputs(obj,history, fps, pixsize,...
                                 binning, spaceorigin,...
                                 timebinning, timeorigin, sourcePath, extra_specs)
           
            if(~isa(extra_specs, 'containers.Map'))
               error("extra_specs must be a containers.Map") 
            end
            
            if(~ischar(history) && ~isstring(history))
                error("history shoud be string or char")
            end
            
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
    end
end

