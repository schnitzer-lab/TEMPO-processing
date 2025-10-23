function W = limitFiltersTimeResolved(W, varargin)
 
    options = defaultOptions();
    if(~isempty(varargin))
        options = getOptions(options, varargin);
    end

    [nx,ny,nt,nchunks] = size(W); 
    
    W_flat = reshape(W, [nx*ny,nt,nchunks]);

%     for i_s = 1:(nx*ny)
    parfor i_s = 1:(nx*ny)
        
        ws = squeeze(W_flat(i_s,:,:));
        if(size(ws,1) == 1), ws = ws'; end

        for i_ch = 1:nchunks
           if(all(isnan( ws(:, i_ch) ))), continue; end

           options_limit = options;
           if(length(options.fref) > 1), options_limit.fref = options.fref(i_ch); end

           ws(:, i_ch) = limitFilter(ws(:, i_ch), options_limit);
        end
        W_flat(i_s,:,:) = ws;
    end
    
    W = reshape(W_flat, [nx,ny,nt,nchunks]);
end
%%

function options = defaultOptions()

    options.fref = [];
    options.max_amp_rel = 1.2; % relative to regression at fref
    options.flim_max = 1;

    options.max_phase = pi;
    options.max_delay = Inf; % normalized: max_delay(s)*fps(Hz)
end