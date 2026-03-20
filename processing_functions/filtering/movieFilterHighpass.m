function fullpath_out = ...
    movieFilterHighpass(fullpath, f0, wp, varargin)

    [basepath, basefilename, ext, postfix] = filenameSplit(fullpath, '_');
    
    options = defaultOptions(basepath);
    if(~isempty(varargin))
        options = getOptions(options, varargin);
    end
    %%

    movie_specs = rw.h5readMovieSpecs(fullpath);
    %%
    
    paramssummary = ['f0=', num2str(f0), 'wp', num2str(wp)];
    paramssummary_complete = ['highpass', paramssummary, ...
        'attn=', num2str(options.attn),  'rppl=',num2str(options.rppl), ...
        'fps=', num2str(movie_specs.getFps())];
    %%

    filterpath = fullfile(options.filtersdir, ['/filter_', paramssummary_complete,  '.csv']);  
    %%

    displog("computing time-domain filter")

    if( ~isfile(filterpath) ) 
        if(~isfolder(options.filtersdir)), mkdir(options.filtersdir); end
        makeFilterHighpass(filterpath, f0, wp, 'fps', movie_specs.getFps(), ...
            'attn', options.attn, 'rppl', options.rppl); 
    end 
    conv_trans = readmatrix(filterpath);
    
    fig_filter = plt.getFigureByName('Convolutional Filter Illustration');
    set(gcf, 'Units', 'Normalized', 'OuterPosition', [0.5, 0.5, .4, 0.3])
    plt.ConvolutionalBandpassFilter(conv_trans, movie_specs.getFps(), f0, ...
        wp, 0, options.attn, options.rppl);
    drawnow();
    %%

    displog("convolving with the filter")

    options_conv = struct('diagnosticdir', options.diagnosticdir, ...
            'remove_mean', true, 'shape', 'valid',...
            'postfix_new', "_hp"+paramssummary+"v", ...
            'outdir', options.outdir, 'skip', options.skip);

    if(isempty(options.exepath))
        [fullpath_out,existed] = ...
            movieConvolutionPerPixel(fullpath, filterpath, options_conv);
    else
        % 3-4x faster, but requires a compiled executable
        [fullpath_out,existed] = ...
            movieConvolutionPerPixelExt(fullpath, filterpath, options.exepath, options_conv);
    end
    %%

    if(~existed)

        % not a great way - but doesn't reqiere overwriting the whole /specs in .h5
        specs_out = rw.h5readMovieSpecs(fullpath_out);
        specs_out.AddFrequencyRange(f0, []);
        rw.h5writeStruct(fullpath_out,  specs_out.extra_specs('frange_valid'), ...
            '/specs/extra_specs/frange_valid');   

            [~,filename_out,~]=fileparts(fullpath_out);
    
        saveas(fig_filter, fullfile(options.diagnosticdir, filename_out + '_filter.fig'))
        saveas(fig_filter, fullfile(options.diagnosticdir, filename_out + '_filter.png'))
    end
    %%

end


function options = defaultOptions(basepath)
   
    options.attn = 1e5; % min attenuation outside pass-band
    options.rppl = 1e-2; % max ripple in the pass-band
        
    options.exepath = []; % to perform convolution with external compiled routine
    
    options.filtersdir = basepath ;%;

    options.diagnosticdir = fullfile(basepath, 'diagnostic', 'filterExternalHighpass');
    options.outdir = basepath;
    
    options.skip = true;
    options.keep_valid_only = true;
end


