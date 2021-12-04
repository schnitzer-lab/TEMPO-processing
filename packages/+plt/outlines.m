function outlines(countors, varargin)
    tf = ishold;
    for i_r = 1:size(countors, 3)
        plot(countors(:,1,i_r), countors(:,2,i_r), varargin{:}); hold on;
    end
    if(~tf) hold off; end
end

