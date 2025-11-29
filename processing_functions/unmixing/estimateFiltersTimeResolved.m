function Wxy = ...
    estimateFiltersTimeResolved(Mg, Mr, wn, no, chunks, varargin)

    assert(all(size(Mg)==size(Mr)), "estimateFilters: movies Mg and Mr should be of the same size");
    options = parseInputs(varargin{:});
    
    [nx, ny] = size(Mg, [1,2]); 
    nchunks = size(chunks,1);

    Mg_flat = reshape(Mg, [nx*ny, size(Mg,3)])'; clear('Mg');
    Mr_flat = reshape(Mr, [nx*ny, size(Mr,3)])'; clear('Mr');
    Wxy_flat = NaN([nx*ny, wn, nchunks]);


    for p1 = 1:options.npixatonece:(nx*ny)
        p2 = min(p1 + options.npixatonece - 1, nx*ny);

        for i_ch = 1:nchunks
            if(options.usereg)
                if(~isempty(options.frefs)), fref=options.frefs(i_ch); 
                else, fref = []; end
                Wxy_flat(p1:p2, :, i_ch) = estimateFilterReg(...
                    Mg_flat(chunks(i_ch,1):chunks(i_ch,2), p1:p2), ...
                    Mr_flat(chunks(i_ch,1):chunks(i_ch,2), p1:p2), wn, no, ...
                        1., [], fref)'; 
            else
                Wxy_flat(p1:p2, :, i_ch) = estimateFilter(...
                    Mg_flat(chunks(i_ch,1):chunks(i_ch,2), p1:p2), ...
                    Mr_flat(chunks(i_ch,1):chunks(i_ch,2), p1:p2), wn, no)'; 
            end
        end
    end
    
    Wxy = reshape(Wxy_flat, [nx,ny,wn,nchunks]);
end
%%

function [options,p] = parseInputs(varargin)
    
    p = inputParser();
    isinrange = @(x,a,b) all(isnumeric(x)&(x>=a)&(x<=b));

    p.addParameter('npixatonece', Inf, @(x)isinrange(x,1,Inf));
   
    % use direct or regularized filter estimation
    p.addParameter('usereg', false, @(x)islogical(x));
    % ref frequencies for regularized filter estimation
    p.addParameter('frefs', [], @(x)isinrange(x,0,1));     
    
    p.parse(varargin{:});
    options = p.Results;
end