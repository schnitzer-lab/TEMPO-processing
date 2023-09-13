
function Mg_hemo = applyFilters(Mr, Wxy)
    if(ndims(Wxy) < 3) % to support a single filter for the whole movie
        Wxy = ...
            reshape(repelem(Wxy, prod(size(Mr, [1,2]))), [size(Mr, [1,2]), length(Wxy)] );
    end
    
    [nx, ny] = size(Mr, [1,2]);
       
    % somehow parfor works better without nested loops... 
    Mr = reshape(Mr, [nx*ny, size(Mr, 3)]);
    Wxy = reshape(Wxy, [nx*ny, size(Wxy,3)]);
    
    Mg_hemo = zeros(size(Mr), class(Mr));
    
%     ppm = ParforProgressbar(nx*ny, 'title', 'applyFilters: parfor progress');
    parfor i_s = 1:(nx*ny)
            x3 = conv(Mr(i_s,:)', Wxy(i_s,:)', 'same');
%             x3 = [x3(2:end);x3(end)];
            Mg_hemo(i_s,:) = x3;
%             ppm.increment();
    end
%     delete(ppm);
    
    Mg_hemo = reshape(Mg_hemo, [nx,ny,size(Mg_hemo,2)]);
    
%     parfor ix = 1:nx
%         for iy = 1:ny
%     %         x1 = squeeze(Mg(ix,iy,:));
%             x2 = squeeze(Mr(ix,iy,:));
%             w = squeeze(Wxy(ix,iy,:));
%             x3 = conv(x2, w, 'same');
%             x3 = [x3(2:end);x3(end)];
%             Mg_hemo(ix,iy,:) = x3; %*std(x1)/std(x3)
%         end
%     % disp(ix)
%     end
end