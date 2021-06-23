function movie_specs = h5readMovieSpecs(h5filename, specspath)
%h5readMovie reads specs (MovieSpecs class object) from .h5 movie file
    if(nargin < 2)
        specspath = '/specs';
    end
    
    specs_struct = rw.h5readStruct(h5filename, specspath);
    
    movie_specs = MovieSpecs( cell2mat(specs_struct.history), ...
                              specs_struct.fps,...
                              specs_struct.pixsize,... 
                              specs_struct.binning,... 
                              specs_struct.spaceorigin,... 
                              specs_struct.timebinning,... 
                              specs_struct.timeorigin,... 
                              cell2mat(specs_struct.sourcePath));
                          
    if(isfield(specs_struct, 'extra_specs'))
        names = fieldnames(specs_struct.extra_specs);
        values = struct2cell(specs_struct.extra_specs);
        for i_e = 1:length(names)                
            movie_specs.extra_specs(names{i_e}) = values{i_e};
        end
    end
                                   
end

