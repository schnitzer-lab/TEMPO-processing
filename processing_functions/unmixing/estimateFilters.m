function Wxy = estimateFilters(Mg, Mr, wn, no, varargin)

    assert(all(size(Mg)==size(Mr)), "estimateFilters: movies Mg and Mr should be of the same size");
    options = parseInputs(varargin{:});
    
    [nx, ny] = size(Mg,[1,2]); 

    Mg_flatT = reshape(Mg, [nx*ny, size(Mg,3)])'; clear('Mg');
    Mr_flatT = reshape(Mr, [nx*ny, size(Mr,3)])'; clear('Mr');
    Wxy_flat = nan([nx*ny, wn], class(Mr_flatT));

    for p1 = 1:options.npixatonece:(nx*ny)
        p2 = min(p1 + options.npixatonece - 1, nx*ny);
        
        if(options.usereg)
            Wxy_flat(p1:p2,:) = ...
                estimateFilterReg(Mg_flatT(:,p1:p2), Mr_flatT(:,p1:p2), wn, no, ...
                    1, [], options.fref)'; 
        else
            Wxy_flat(p1:p2,:) = ...
                estimateFilter(Mg_flatT(:,p1:p2), Mr_flatT(:,p1:p2), wn, no)'; 
        end
    end
     
    Wxy = reshape(Wxy_flat, [nx,ny,wn]);
end
%%

function [options,p] = parseInputs(varargin)
    
    p = inputParser();
    isinrange = @(x,a,b) all(isnumeric(x)&(x>=a)&(x<=b));

    p.addParameter('npixatonece', Inf, @(x)isinrange(x,1,Inf));
   
    % use direct or regularized filter estimation
    p.addParameter('usereg', false, @(x)islogical(x));
    % ref frequencies for regularized filter estimation
    p.addParameter('fref', [], @(x)isinrange(x,0,1));   
    
    p.parse(varargin{:});
    options = p.Results;
end