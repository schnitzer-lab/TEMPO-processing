%  path = callFunctionPath(level)
%
% returns the filename of a function from where it is called from, or
% (level) levels above in stack
function path = callFunctionPath(level)
    if(nargin < 1)
        level = 0;
    end

    stack = dbstack('-completenames');
    if( numel(stack) >= 2+level)
        path = stack(2+level).name;
    else 
        path = 'base';
    end

end

