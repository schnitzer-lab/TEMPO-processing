function movie_specs = h5readMovieSpecs(h5filename, specspath)
%h5readMovie reads specs (MovieSpecs class object) from .h5 movie file
    if(nargin < 2)
        specspath = '/specs';
    end
    
    specs_struct = rw.h5readStruct(h5filename, specspath);

    if(~isfield(specs_struct, 'history_params')) 
        specs_struct.history_params = '[]'; 
    end
    if(~isfield(specs_struct, 'channel_id') || ...
       ~isfield(specs_struct, 'recording_id') || ...
       ~isfield(specs_struct, 'mouse_id')) 
        warning("no id-s in file, deducing from sourcePath");
        path_parts = strsplit(char(specs_struct.sourcePath), filesep);
        specs_struct.mouse_id = path_parts{end-3};
        specs_struct.recording_id = fullfile(path_parts{end-4}, path_parts{end-3}, path_parts{end-2}, path_parts{end-1});
        specs_struct.channel_id = regexp(path_parts{end}, '(?<=-c)[A-Z]', 'match', 'once');
    end
    movie_specs = MovieSpecsTEMPO(specs_struct.fps,...
                                  specs_struct.timebinning,... 
                                  specs_struct.timeorigin,... 
                                  specs_struct.pixsize,... 
                                  specs_struct.binning,... 
                                  specs_struct.spaceorigin, ...
                                  specs_struct.mouse_id, ...
                                  specs_struct.recording_id, ...
                                  specs_struct.channel_id, ...
                                  specs_struct.sourcePath,... 
                                  specs_struct.history, ...
                                  specs_struct.history_params);
                          
    if(isfield(specs_struct, 'extra_specs'))
        names = fieldnames(specs_struct.extra_specs);
        values = struct2cell(specs_struct.extra_specs);
        for i_e = 1:length(names)                
            if isa(values{i_e}, 'cell') 
                %so that strings are are not symbol-by-symbol cell array as default in matlab's h5postprocessstrings
                values{i_e} = cell2mat(values{i_e});
            end
            movie_specs.extra_specs(names{i_e}) = values{i_e};
        end
    end
                                   
end

