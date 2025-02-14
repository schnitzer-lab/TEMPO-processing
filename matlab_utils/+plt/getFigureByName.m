function fig = getFigureByName(fig_name, ontop)
    
    if(nargin < 2), ontop = true; end

    fig = findobj( 'Type', 'Figure', 'Name', fig_name );
    if(isempty (fig)), fig=figure('Name', fig_name); end
    if(ontop), figure(fig(1)); end
end

