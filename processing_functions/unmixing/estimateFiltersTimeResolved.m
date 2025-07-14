function Wxy = ...
    estimateFiltersTimeResolved(Mg, Mr, wn, no, chunks, frefs)

    if(nargin < 5), fref = []; end
    
    [nx, ny] = size(Mg, [1,2]); 
    nchunks = size(chunks,1);

    Wxy = NaN([nx*ny, wn, nchunks]);
    Mg_flat = reshape(Mg, [nx*ny, size(Mg,3)]); clear('Mg');
    Mr_flat = reshape(Mr, [nx*ny, size(Mr,3)]); clear('Mr');

    for i_ch = 1:nchunks
        Wxy(:, :, i_ch) = estimateFilterReg(...
            Mg_flat(:, chunks(i_ch,1):chunks(i_ch,2))', ...
            Mr_flat(:, chunks(i_ch,1):chunks(i_ch,2))', wn, no, ...
            1, [], frefs(i_ch))'; 
        % Wxy(:, :, i_ch) = estimateFilter(...
        %     Mg_flat(:, chunks(i_ch,1):chunks(i_ch,2))', ...
        %     Mr_flat(:, chunks(i_ch,1):chunks(i_ch,2))', wn, no)'; 
    end
    
    Wxy = reshape(Wxy, [nx,ny,wn,nchunks]);
end
%%