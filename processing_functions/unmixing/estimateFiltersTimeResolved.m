function Wxy = ...
    estimateFiltersTimeResolved(Mg, Mr, wn, no, chunks, varargin)

    assert(all(size(Mg)==size(Mr)), "estimateFilters: movies Mg and Mr should be of the same size");
    options = parseInputs(varargin{:});
    
    [nx, ny] = size(Mg, [1,2]); 
    nchunks = size(chunks,1);

    Wxy = NaN([nx*ny, wn, nchunks]);
    Mg_flat = reshape(Mg, [nx*ny, size(Mg,3)]); clear('Mg');
    Mr_flat = reshape(Mr, [nx*ny, size(Mr,3)]); clear('Mr');

    for i_ch = 1:nchunks
        if(options.usereg)
            if(~isempty(options.frefs)), fref=options.frefs(i_ch); 
            else, fref = []; end
            Wxy(:, :, i_ch) = estimateFilterReg(...
                Mg_flat(:, chunks(i_ch,1):chunks(i_ch,2))', ...
                Mr_flat(:, chunks(i_ch,1):chunks(i_ch,2))', wn, no, ...
                    1., [], fref)'; 
        else
            Wxy(:, :, i_ch) = estimateFilter(...
                Mg_flat(:, chunks(i_ch,1):chunks(i_ch,2))', ...
                Mr_flat(:, chunks(i_ch,1):chunks(i_ch,2))', wn, no)'; 
        end
    end
    
    Wxy = reshape(Wxy, [nx,ny,wn,nchunks]);
end
%%

function [options,p] = parseInputs(varargin)
    
    p = inputParser();
    isinrange = @(x,a,b) all(isnumeric(x)&(x>=a)&(x<=b));
   
    % use direct or regularized filter estimation
    p.addParameter('usereg', false, @(x)islogical(x));
    % ref frequencies for regularized filter estimation
    p.addParameter('frefs', [], @(x)isinrange(x,0,1));     
    
    p.parse(varargin{:});
    options = p.Results;
end