function displog(varargin)

    stack = dbstack;
    if numel(stack) >= 2
        callerName = stack(2).name;
    else
        callerName = '';
    end

    fprintf("<"+string(datetime('now', 'Format', 'yyyy-MM-dd''T''HH:mm:ss'))+">");
    fprintf(" "+callerName+": ");
    disp(varargin{:})
end