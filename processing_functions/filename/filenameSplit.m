function [filedir, basename, fileext, filepostfix] = filenameSplit(filepath, sep, include_sep)
    if(nargin < 2) sep = ''; end
    if(nargin < 3) include_sep = false; end
        
    [filedir, filename, fileext] = fileparts(string(filepath));
    
    if(nargout > 3)
        splits = strsplit(filename, sep);
        basename = splits(1);
        
        if(length(splits)  >= 2)
            if(include_sep)
                basename = basename + sep;
                filepostfix = join([splits(2:end)], sep);
            else
                filepostfix = string(sep) + join([splits(2:end)], sep);
            end
        else
            filepostfix = "";
        end
    else
        basename = filename;
    end
end

