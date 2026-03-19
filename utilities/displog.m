function displog(varargin)
    fprintf("<"+string(datetime('now', 'Format', 'yyyy-MM-dd''T''HH:mm:ss'))+"> ");
    disp(varargin{:})
end