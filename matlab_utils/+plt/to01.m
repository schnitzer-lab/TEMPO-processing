function varargout = to01(M,q)
    if nargin < 2
        q(1) = 0;
        q(2) = 1;
    end
    
    if(length(q) < 2) q = [q, 1-q]; end
    
    
    if(q(1) == 0)
        x1 = min(M(:));
    else
        x1 = quantile(M(:), q(1) );
    end
    
    if(q(2) == 1)
        x2 = max(M(:));
    else
        x2 = quantile(M(:), q(2) );
    end

    if(x1 ~= x2)
        varargout{1} = M/(x2-x1) - x1/(x2-x1);
    else
        varargout{1} = zeros(size(M));
    end
    
    varargout{1}(varargout{1} > 1) = 1;
    varargout{1}(varargout{1} < 0) = 0;
    
    if(nargout > 1) 
        varargout{2} = x2;
        varargout{3} = (x2-x1); 
    end

end
