 
function Mg_hemo = applyFiltersTimeResolved(Mr, W, chunks, chunks_nooverlap)
     
    [nx, ny, nt] = size(Mr);

    % to support a single filter for the whole movie
    if(ndims(W) == 2)
        W =  reshape(repelem(W, nx*ny,1), [nx, ny, size(W,1), size(W,2)]);
    end
    [wn,nchunks] = size(W, [3, 4]);
    
    if(nchunks ~= size(chunks,1)), error('number of filters != number of chunks'); end

    % parfor works faster without nested loops...
    Mr = reshape(Mr, [nx*ny, nt]);
    W = reshape(W, [nx*ny, wn, nchunks]);
    
    Mg_hemo = zeros(size(Mr), class(Mr));
    
    parfor i_s = 1:(nx*ny)
        
        mr_raw = Mr(i_s, :)';
        mg_hemo = nan(nt,1);
        ws = squeeze(W(i_s,:,:));
        if(nchunks == 1), ws = ws'; end

        for i_ch = 1:nchunks
            
            w = ws(:,i_ch);
            x = conv(mr_raw(chunks(i_ch,1):chunks(i_ch,2)), w, 'same');

            mg_hemo(chunks_nooverlap(i_ch,1):chunks_nooverlap(i_ch,2))  = ...
                x((chunks_nooverlap(i_ch,1)-chunks(i_ch,1)+1):(chunks_nooverlap(i_ch,2)-chunks(i_ch,1)+1));
        end
        
        Mg_hemo(i_s, :) = mg_hemo;
    end
    
    Mg_hemo = reshape(Mg_hemo, [nx,ny,size(Mg_hemo,2)]);
   
end