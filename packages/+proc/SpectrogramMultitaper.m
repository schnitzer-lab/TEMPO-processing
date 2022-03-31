% ConvolutionPerPixelExt - Calls external routine for per-pixel convolution with given filter file
%
% SYNTAX:
% st = SpectrogramMultitaper(x, w)- use with default options
% st = SpectrogramMultitaper(x, w, 'option1', value1)
%
% INPUTS:
% - x - input signal
% - w - time window size
% - options - described below
%
% OUTPUTS:
% - st - 2d spectrogram
%
% OPTIONS:
%   overlap (w/2) - overlap of the adjacent time windows
%   nw (1) - time-bandwidth product for multitaper transform.
%   DropLastTaper (false) - 'DropLastTaper' option of the matlab pmtm
%
% DEMO:
% fps = 120; n = 2^12; ts = (1:n)'/fps;
% x = sin( 2*pi*((2*f + ts*1/3).*ts - f*1/5*cos(ts*10/5) )) +...
%     sin( 2*pi*((0.2*f + ts*1/2).*ts  )).*(exp(-(ts - 3).^2./2^2) + exp(-(ts - 16).^2./2^2)) +...
%     sin( 2*pi*((4*f - ts*1.75/2).*ts  )) + 0.5*randn(n,1);
% st = proc.SpectrogramMultitaper(x, w, 'overlap', dw);
% imagesc(st);  set(gca,'ColorScale','log')
%
function st = SpectrogramMultitaper(x, w, varargin)

    options = DefaultOptions(w);
    if nargin>=2
        options=getOptions(options,varargin);
    end
    
    if(options.overlap ~= round(options.overlap))
        error('overlap must be integer');
    end
    
    n_widows = floor((length(x) - w)/(w - options.overlap )) + 1; %floor(length(x)/options.overlap ) -1;
    nf = floor(w/2)+1+(ceil(w/2)-1)*(~isreal(x));
    st = nan(nf, n_widows);
    % st = [];
    for i_t = 1:n_widows
%         disp(i_t)
        xrange = (1+(i_t-1)*(w - options.overlap ) ):(w + (i_t-1)*(w - options.overlap ) );
        
        if(~any(isnan(x(xrange))))
            z = pmtm(x(xrange), options.nw, w, ...
               'DropLastTaper', options.DropLastTaper);
        % in matlab 2020b one can do: 'Tapers','sine'
            if(options.correct1f)
                fs = (1:length(z))';
                rf = robustfit(log(fs), log(z));
                zfit = exp(rf(1))*(fs.^rf(2));
                z = z./zfit;
            end
            st(:,i_t) = z; 
        else
            st(:,i_t) = NaN(length(st(:,i_t)),1);
        end
    end

end


function options =  DefaultOptions(w)
    options.overlap = floor(w/2);
    options.nw = 1;
    options.correct1f = false; %correct for 1/f^a specral decay
    options.DropLastTaper = false;
end
