function fullpath_out_valid = ...
    movieFilterExternalHighpass(fullpath, f0, wp, varargin)

    [basepath, basefilename, ext, postfix] = filenameSplit(fullpath, '_');
    
    options = defaultOptions(basepath);
    if(~isempty(varargin))
        options = getOptions(options, varargin);
    end


    postfix_new = "_hp";
    postfix_valid = 'v';
    %%

    movie_specs = rw.h5readMovieSpecs(fullpath);
    %%
    
    paramssummary = ['f0=', num2str(f0), 'wp', num2str(wp)];
    paramssummary_complete = ['highpass', paramssummary, ...
        'attn=', num2str(options.attn), 'rppl=',num2str(options.rppl), 'fps=', num2str(movie_specs.getFps())];

    %%
    
    if (~isfolder(options.outdir)) mkdir(options.outdir); end
    if (~isfolder(options.illustrdir)) mkdir(options.illustrdir); end
    if (~isfolder(options.diagnosticdir)) mkdir(options.diagnosticdir); end

    filename_out = basefilename + postfix + postfix_new + paramssummary;
    fullpath_out = fullfile(options.outdir, filename_out + ext);
    fullpath_out_valid = fullfile(options.outdir, filename_out + postfix_valid + ext);
    %%
    
    if (isfile(fullpath_out_valid))
        if(options.skip)
            disp("movieFilterExternalHighpass: Output file exists. Skipping: " + fullpath_out_valid)
            return;
        else
            warning("movieFilterExternalHighpass: Output file exists. Deleting: " + fullpath_out_valid);
            delete(fullpath_out);
            delete(fullpath_out_valid);
        end     
    end

    filterpath = fullfile(options.filtersdir, ['/filter_', paramssummary_complete,  '.csv']);  
    %%

    if( ~isfile(filterpath) ) 
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

    [status,cmdout] = ...
        ConvolutionPerPixelExt(char(fullpath), char(filterpath), char(fullpath_out), ...
            'delete', true, 'num_cores', options.num_cores, ...
            'exepath', char(options.exepath), 'remove_mean', true);
    %%
    
    % not a great way - but doesn't reqiere overwriting the whole /specs in .h5
    specs_out = rw.h5readMovieSpecs(fullpath_out);
    specs_out.AddFrequencyRange(f0, []);
    rw.h5writeStruct(fullpath_out,  specs_out.extra_specs('frange_valid'), ...
        '/specs/extra_specs/frange_valid');    
    %%

    offset = ceil(length(conv_trans)*0.5);
    valid_range = [offset, rw.h5getDatasetSize(fullpath_out, '/mov', 3) - offset];

    fullpath_out_valid = movieTimeCrop(fullpath_out, valid_range, 'postfix_new', postfix_valid); %TODO: function that can accept either range or a single number
    %%

%     savesummaryFilteredMovie(fullpath, fullpath_out, valid_range, filename_out,...
%         options.diagnosticdir)
    
    [M_raw, specs] = rw.h5readMovie(fullpath);
    nan_mask = 1 - any(isnan(M_raw), 3); nan_mask(nan_mask == 0) = NaN; %To force mean remove nan pixels completely;
    m_raw = squeeze(sum(M_raw.*nan_mask, [1,2], 'omitnan'));
    clear('M_raw');

    [M_filtered, ~] = rw.h5readMovie(fullpath_out);
    m_filtered = squeeze(sum(M_filtered.*nan_mask, [1,2], 'omitnan'));
    clear('M_filtered');
    %%    

    fig_traces = plt.getFigureByName('Filtering: mean traces');
    
    plt.tracesComparison([m_raw, m_raw - m_filtered, m_filtered], ...
        'spacebysd', [0,0,3], 'fps', specs.getFps(), 'fw', 0.2, ...
        'labels', ["original", "difference", "filtered"]);
    sgtitle([filename_out, "mean traces"], 'interpreter', 'none', 'FontSize', 10)

    subplot(2,1,1); hold on;
    xline(valid_range(1)/specs.getFps(), '--'); xline(valid_range(end)/specs.getFps(), '--'); 
    hold off
    drawnow();
    %%
    
    saveas(fig_filter, fullfile(options.diagnosticdir, filename_out + '_filter.fig'))
    saveas(fig_filter, fullfile(options.diagnosticdir, filename_out + '_filter.png'))
    saveas(fig_traces, fullfile(options.diagnosticdir, filename_out + '_traces.fig'))
    saveas(fig_traces, fullfile(options.diagnosticdir, filename_out + '_traces.png'))
    %%
    
    if(options.keep_valid_only)
        delete(fullpath_out);
        fullpath_out = [];
    end
end


function options = defaultOptions(basepath)
   
    options.attn = 1e5; % min attenuation outside pass-band
    options.rppl = 1e-2; % max ripple in the pass-band
    
    options.exepath = '../../../analysis/c_codes/compiled/hdf5_movie_convolution.exe';
    options.num_cores = floor(feature('numcores')/4);
    
    options.filtersdir = basepath ;%;
    
    options.illustrdir = basepath + "\illustrations\";
    options.diagnosticdir = basepath + "\diagnostic\filterExternalHighpass\";
    options.outdir = basepath;
    
    options.skip = true;
    options.keep_valid_only = true;
end


