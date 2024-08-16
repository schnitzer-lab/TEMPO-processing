
function Mg_hemo = applyFilters(Mr, Wxy)
     
    [nx, ny] = size(Mr, [1,2]);

    % to support a single filter for the whole movie
    if(isvector(Wxy))
        Wxy =  reshape(repelem(Wxy, nx*ny),  [size(Mr,[1,2]), []]);
    end
           
    % parfor works faster without nested loops...
    Mr = reshape(Mr, [nx*ny, size(Mr, 3)]);
    Wxy = reshape(Wxy, [nx*ny, size(Wxy,3)]);
    
    Mg_hemo = zeros(size(Mr), class(Mr));
    
    parfor i_s = 1:(nx*ny)
        Mg_hemo(i_s,:) = conv(Mr(i_s,:)', Wxy(i_s,:)', 'same');
    end
    
    Mg_hemo = reshape(Mg_hemo, [nx,ny,size(Mg_hemo,2)]);
   
end