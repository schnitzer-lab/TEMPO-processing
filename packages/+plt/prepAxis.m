function prepAxis(prep_cb)

    if(nargin < 1), prep_cb = false; end

    xlabel(' '); ylabel(' '); 
    title(' ');
    if(prep_cb)
        cb = colorbar(); 
        cb.Label.String = ' '; cb.Label.Rotation = -90;
    end
end

