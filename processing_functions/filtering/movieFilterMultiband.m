function fullpath_out = movieFilterMultiband(fullpath, f0s, wps, varargin)

    f0s = f0s(:)';
    if(isscalar(wps)), wps = repmat(wps, 1, numel(f0s)); end
    wps = wps(:)';

    [basepath, ~, ~] = fileparts(fullpath);

    options = defaultOptions(basepath, wps);
    if(~isempty(varargin))
        options = getOptions(options, varargin);
    end
    %%

    movie_specs = rw.h5readMovieSpecs(fullpath);
    %%

    paramssummary = ['f0=', vec2str(f0s),'wp=',vec2str(wps)];
    paramssummary_complete = ['multiband', paramssummary, ...
        'wr=', vec2str(options.wr), 'attn=', vec2str(options.attn),...
        'rppl=', vec2str(options.rppl), 'fps=', num2str(movie_specs.getFps()) ];
    %%

    filterpath = fullfile(options.filtersdir, ['/filter_', paramssummary_complete,  '.csv']);
    %%

    displog("computing time-domain multiband filter")

    if( ~isfile(filterpath) )
        if(~isfolder(options.filtersdir)), mkdir(options.filtersdir); end
        makeFilterMultiband(filterpath, f0s, wps, 'wr', options.wr, 'fps', movie_specs.getFps(), ...
            'attn_r', options.attn, 'attn_l', options.attn*10, 'rppl', options.rppl);
    end
    conv_trans = readmatrix(filterpath);

    fig_filter = plt.getFigureByName('Convolutional Filter Illustration');
    set(gcf, 'Units', 'Normalized', 'OuterPosition', [0.5, 0.5, .4, 0.3])
    plt.ConvolutionalMultibandFilter( conv_trans, movie_specs.getFps(), f0s,...
        wps, options.wr, options.attn, options.rppl);
    drawnow();
    %%

    displog("convolving with the filter")

    options_conv = struct('diagnosticdir', options.diagnosticdir, ...
            'remove_mean', true, 'shape', 'valid',...
            'postfix_new', "_mb"+paramssummary+"v", ...
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
        specs_out.AddFrequencyRange(min(f0s-wps), max(f0s+wps));
        rw.h5writeStruct(fullpath_out,  specs_out.extra_specs('frange_valid'), ...
            '/specs/extra_specs/frange_valid');

        [~,filename_out,~]=fileparts(fullpath_out);

        saveas(fig_filter, fullfile(options.diagnosticdir, filename_out + '_filter.fig'))
        saveas(fig_filter, fullfile(options.diagnosticdir, filename_out + '_filter.png'))
    end
    %%

end


function s = vec2str(v)
    % space-free numeric-vector formatting: filterpath/fullpath_out built
    % from this string are passed unquoted to the external convolution
    % executable (ConvolutionPerPixelExt.m), so spaces would break the
    % command-line call.
    s = strrep(mat2str(v), ' ', ',');
end

function options = defaultOptions(basepath, wps)

    options.wr = wps;
    options.attn = 1e5; % min attenuation outside pass-band
    options.rppl = 1e-2; % max ripple in the pass-band

    options.exepath = []; % to perform convolution with external compiled routine

    options.filtersdir = basepath ;%;

    options.diagnosticdir = fullfile(basepath, 'diagnostic', 'filterExternalHighpass');
    options.outdir = basepath;

    options.skip = true;
    options.keep_valid_only = true;
end
