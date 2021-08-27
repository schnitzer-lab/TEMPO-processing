function [movie, movie_specs] = h5readMovie(h5filename, varargin)
%h5readMovie reads .h5 movie and associated specs
    
    options = defaultOptions();
    if(~isempty(varargin))
        options = getOptions(options, varargin);
    end
    
    movie_specs = rw.h5readMovieSpecs(h5filename);
    movie = h5read(h5filename, options.dataset, ...
        [1, 1, options.frame_start], [Inf, Inf, options.frames_num]);
end


function options = defaultOptions()
    
    options.dataset = '/mov';
    options.frame_start = 1;
    options.frames_num = Inf;
end