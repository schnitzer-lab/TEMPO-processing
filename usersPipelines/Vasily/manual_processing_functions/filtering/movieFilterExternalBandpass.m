function [fullpath_out_valid, fullpath_out] = movieFilterExternalBandpass(fullpath, f0, wp, varargin)

    [basepath, basefilename, ext, postfix] = filenameSplit(fullpath, '_');
    
    options = defaultOptions(basepath, wp);
    if(~isempty(varargin))
        options = getOptions(options, varargin);
    end


    postfix_new = "_bp";
    %%

    movie_specs = rw.h5readMovieSpecs(fullpath);
    %%
    
    paramssummary = ['f0=', num2str(f0),'wp=',num2str(wp)];
    paramssummary_complete = ['bandpass', paramssummary, ...
        'wr=', num2str(options.wr), 'attn=', num2str(options.attn),...
        'rppl=', num2str(options.rppl), 'fps=', num2str(movie_specs.getFps()) ];

    %%
    
    if (~isfolder(options.outdir)) mkdir(options.outdir); end
    if (~isfolder(options.diagnosticdir)) mkdir(options.diagnosticdir); end

    filename_out = basefilename + postfix + postfix_new + paramssummary;
    fullpath_out = fullfile(options.outdir, filename_out + ext);
    fullpath_out_valid = fullfile(options.outdir, basefilename + postfix + postfix_new + paramssummary +'v'+ ".h5");
    
    if (isfile(fullpath_out_valid))
        if(options.skip)
            disp("movieFilterExternalHighpass: Output file exists. Skipping: " + fullpath_out)
            return;
        else
            warning("movieFilterExternalHighpass: Output file exists. Deleting: " + fullpath_out);
            delete(fullpath_out);
            delete(fullpath_out_valid);
        end     
    end

    filterpath = fullfile(options.filtersdir, ['/filter_', paramssummary_complete,  '.csv']);
    %%

    if( ~isfile(filterpath) ) 
        makeFilterBandpass(filterpath, f0, wp, 'wr', options.wr, 'fps', movie_specs.getFps(), ...
            'attn_r', options.attn, 'attn_l', options.attn*10, 'rppl', options.rppl); 
    end 
    conv_trans = readmatrix(filterpath);
    
    fig_filter = plt.getFigureByName('Convolutional Filter Illustration');
    set(gcf, 'Units', 'Normalized', 'OuterPosition', [0.5, 0.5, .4, 0.3])
    plt.ConvolutionalBandpassFilter( conv_trans, movie_specs.getFps(), f0, wp, options.wr, options.attn, options.rppl); drawnow;
    %%

    [status,cmdout] = ConvolutionPerPixelExt(char(fullpath), char(filterpath), char(fullpath_out), ...
        'delete', true, 'num_cores', options.num_cores, ...
        'exepath', char(options.exepath), 'remove_mean', options.remove_mean);
    %%
    
    specs_out = rw.h5readMovieSpecs(fullpath_out);
    specs_out.extra_specs('bandpass_f0') = f0;
    specs_out.extra_specs('bandpass_wp') = wp;
    specs_out.AddFrequencyRange(f0-wp, f0+wp);
    rw.h5saveMovieSpecs(fullpath_out, specs_out, 'rewrite', false);
    %%
    offset = ceil(length(conv_trans)*0.5);
    valid_range = [offset, rw.h5getDatasetSize(fullpath_out, '/mov', 3) - offset];

    fullpath_out_valid = movieTimeCrop(fullpath_out, valid_range, 'postfix_new', 'v'); %TODO: function that can accept either range or a single number
    %%

%     savesummaryFilteredMovie(fullpath, fullpath_out, valid_range, ...
%         basefilename+postfix+postfix_new+paramssummary, options.diagnosticdir)
        
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
    
    if( options.keep_valid_only ) 
        delete(fullpath_out); 
        fullpath_out = [];
    end
end


function options = defaultOptions(basepath, wp)

    options.wr = wp;
    options.attn = 1e5; % min attenuation outside pass-band
    options.rppl = 1e-2; % max ripple in the pass-band
    
    options.remove_mean = true;
    
    options.exepath = '../../../analysis/c_codes/compiled/hdf5_movie_convolution.exe';
    options.num_cores = floor(feature('numcores')/4);
    
    options.filtersdir = basepath;
    
    options.diagnosticdir = basepath + "\diagnostic\filterExternalBandpass\";
    options.outdir = basepath;
    
    options.skip = true;
    options.keep_valid_only = true;
end


