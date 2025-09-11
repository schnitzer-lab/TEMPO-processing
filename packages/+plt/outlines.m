function outlines(countors, x_lim, y_lim, varargin)
    
    if(nargin < 2 || isempty(x_lim)) x_lim = [-Inf,Inf]; end
    if(nargin < 3 || isempty(y_lim)) y_lim = [-Inf,Inf]; end 

    tf = ishold();
    
    ncountors = size(countors, 3);
    if(isempty(countors)), ncountors = 0; end

    for i_r = 1:ncountors
        countors(countors(:,1,i_r) < x_lim(1), 1, i_r) = NaN;
        countors(countors(:,1,i_r) > x_lim(2), 1, i_r) = NaN;
        countors(countors(:,2,i_r) < y_lim(1), 1, i_r) = NaN;
        countors(countors(:,2,i_r) > y_lim(2), 1, i_r) = NaN;
    end

    for i_r = 1:ncountors
        plot(countors(:,1,i_r), countors(:,2,i_r), varargin{:}); hold on;
    end
    if(~tf), hold off; end
end

