function outlines(contours, x_lim, y_lim, varargin)
    
    if(nargin < 2 || isempty(x_lim)), x_lim = [-Inf,Inf]; end
    if(nargin < 3 || isempty(y_lim)), y_lim = [-Inf,Inf]; end 

    tf = ishold();
    
    if(~iscell(contours) && ~isempty(contours))
        contours = squeeze(mat2cell(contours, ...
            size(contours,1), size(contours,2), ones([size(contours,3),1])));
    end

    for i_r = 1:length(contours)
        contours{i_r}(contours{i_r}(:,1) < x_lim(1), 1) = NaN;
        contours{i_r}(contours{i_r}(:,1) > x_lim(2), 1) = NaN;
        contours{i_r}(contours{i_r}(:,2) < y_lim(1), 2) = NaN;
        contours{i_r}(contours{i_r}(:,2) > y_lim(2), 2) = NaN;
    end

    for i_r = 1:length(contours)
        plot(contours{i_r}(:,1), contours{i_r}(:,2), varargin{:}); hold on;
    end
    if(~tf), hold off; end
end

