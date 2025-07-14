function Wxy = estimateFilters(Mg, Mr, wn, no, fref)

    if(nargin < 5), fref = []; end
    
    [nx, ny] = size(Mg,[1,2]); 

    Mg_flatT = reshape(Mg, [nx*ny, size(Mg,3)])'; clear('Mg');
    Mr_flatT = reshape(Mr, [nx*ny, size(Mr,3)])'; clear('Mr');

    % Wxy_flat = estimateFilter(Mg_flatT, Mr_flatT, wn, no)'; 
    Wxy_flat = estimateFilterReg(Mg_flatT, Mr_flatT, wn, no, 1, [], fref)'; 

    Wxy = reshape(Wxy_flat, [nx,ny,wn]);
end
%%
