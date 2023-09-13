function Wxy = estimateFilters(Mg, Mr, dn, dn_overlap, varargin)

    if(mod(dn,2)) dn = dn+1; end
    
    options = defaultOptions();
    if(~isempty(varargin))
        options = getOptions(options, varargin);
    end
    
    nx= size(Mg,1); ny = size(Mg,2);

    % somehow parfor works better without nested loops...
    Wxy = zeros([nx*ny, dn]);
    Mg = reshape(Mg, [nx*ny, size(Mg,3)]);
    Mr = reshape(Mr, [nx*ny, size(Mr,3)]);

%     ppm = ParforProgressbar(nx*ny, 'title', 'estimateFilters: parfor progress');
    parfor i_s = 1:(nx*ny)
        if(all(Mg(i_s,:) == 0) || all(Mr(i_s,:) == 0)) 
            Wxy(i_s, :) = nan(size(Wxy(i_s, :) )); 
            continue; 
        end
%         max_amp = options.max_amp_rel*abs(hilbert(Mr(i_s,:)')\hilbert(Mg(i_s,:)'));

        Wxy(i_s, :) = estimateFilterReg(Mg(i_s,:)', Mr(i_s,:)', ...
            dn, dn_overlap, 'eps', options.eps,...
            'fref', options.fref, 'max_amp_rel', options.max_amp_rel, 'flim_max', options.flim_max, ....
            'max_phase', options.max_phase, 'max_delay', options.max_delay); %ppm.increment();
    end
%     delete(ppm);
    
    Wxy = reshape(Wxy, [nx,ny,dn]);
end
%%

function options = defaultOptions()
    options.eps = 1e-8;
    
    options.fref = [];
    options.max_amp_rel = 1.2; % relative to regression at fref
    options.flim_max = 1;

    options.max_phase = pi;
    options.max_delay = Inf; % normalized: max_delay(s)*fps(Hz)
end