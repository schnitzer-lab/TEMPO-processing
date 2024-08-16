function [filedir, filename, fileext, basefilename, channel, postfix] = filenameParts(filepath, varargin)
    
    options = defaultOptions();
    if(~isempty(varargin))
        options = getOptions(options, varargin);
    end
        
    [filedir, filename, fileext] = fileparts(string(filepath));
    
    [C,matches] = strsplit(filename, options.ch_regex, 'DelimiterType','RegularExpression');
    
    channel = string(matches{1});
    basefilename = string(C{1});
    postfix = string(C{2});
end

function options = defaultOptions()
    options.ch_regex = 'c[GR][1-9]*';
end