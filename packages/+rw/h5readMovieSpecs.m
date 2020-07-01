function movie_specs = h5readMovieSpecs(h5filename)
%h5readMovie reads specs (MovieSpecs class object) from .h5 movie file
    
    movie_specs = MovieSpecs( cell2mat(h5read(h5filename, '/history')), ...
                                       h5read(h5filename, '/fps'),...
                                       h5read(h5filename, '/scale_factor'),... 
                                       h5read(h5filename, '/frame_range'));
                                   
end

