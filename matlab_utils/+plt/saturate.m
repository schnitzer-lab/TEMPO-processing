function varargout = saturate(M,q)
    
    if(length(q) < 2) q = [q,1-q]; end
    
    
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

    varargout{1} = M;
    
    varargout{1}(varargout{1} < x1) = x1;
    varargout{1}(varargout{1} > x2) = x2;
    
    if(nargout > 1) 
        varargout{2} = x1;
        varargout{3} = x2; 
    end

end

 