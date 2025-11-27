function [pks, locs, ws, ps, z] = findpeaksspectral(m, df, Fs, flims, varargin)
    
    if(nargin <= 2 || isempty(Fs)), Fs = 1; end

    z = pmtm(m, df*length(m)/Fs/2); 
    fs = linspace(0,1,(length(z)-1))*Fs/2;
    
 
    if(nargin <= 3 || isempty(flims)), flims = [min(fs), max(fs)]; end
    touse = (fs>flims(1) & fs<flims(2));
    
    
    [pks, locs, ws, ps] = findpeaks(log(z(touse)), fs(touse),...
        varargin{:});
end

