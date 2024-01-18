function fullpath_out = movieRemoveOutlierFrames(fullpath_movie, varargin)
    
    [basepath, filename, ext, basefilename, channel, postfix] = ...
        filenameParts(fullpath_movie);

    options = defaultOptions(basepath);
    if(~isempty(varargin))
        options = getOptions(options, varargin);
    end

    postfix_new = "_or";
    %%
    
    if (~isfolder(options.outdir)) mkdir(options.outdir); end
    if (~isfolder(options.diagnosticdir)) mkdir(options.diagnosticdir); end

    filename_out = basefilename+channel+postfix+postfix_new;
    fullpath_out = fullfile(options.outdir, filename_out + ext);
    
    if (isfile(fullpath_out))
        if(options.skip)
            disp("movieRemoveOutlierFrames: Output file exists. Skipping: " + fullpath_out)
            return;
        else
            warning("movieRemoveOutlierFrames: Output file exists. Deleting: " + fullpath_out);
            delete(fullpath_out);
        end     
    end
    %%
    
    disp("movieRemoveOutlierFrames: reading movie")
    specs = rw.h5readMovieSpecs(fullpath_movie);
    m = rw.h5getMeanTrace(fullpath_movie);
%     [M, specs] = rw.h5readMovie(fullpath_movie);
%     m = squeeze(mean(M,[1,2],'omitnan'));
    %%
    
    disp("movieRemoveOutlierFrames: finding outliers")

    npoints = round(options.dt*specs.getFps());
    %%

    is_outlier = zeros([length(m), 1]);
    m_current = m;
    %%
    while true
        m_movmean = movmean(m_current, npoints, 'Endpoints', 'shrink');
        m_std = movstd(m_current, npoints, 'Endpoints', 'shrink');

        is_outlier_current = abs(m_current-m_movmean) > options.n_sd*m_std;
        if(sum(is_outlier_current) == 0) break; end
        is_outlier = (is_outlier | is_outlier_current);
        m_current(is_outlier) = NaN; 
        m_current = squeeze(imputeNaNT(reshape(m_current, [1,1, length(m)])));
%         plot([m,m_current])
    end
    n_outliers = sum(is_outlier);
    %%
    
    if(n_outliers == 0) 
        disp("movieRemoveOutlierFrames: no outliers found, returning");
        fullpath_out = fullpath_movie;
        return;
    end
    %%
    disp("movieRemoveOutlierFrames: reading movie")
    [M, specs] = rw.h5readMovie(fullpath_movie);

    disp("movieRemoveOutlierFrames: correcting outliers")
    M(:,:,is_outlier) = NaN;
    M = imputeNaNT(M);
    %%

    disp("movieRemoveOutlierFrames: plotting")
    
    m_out = squeeze(sum(M,[1,2],'omitnan'));

    fig_traces = plt.getFigureByName("movieRemoveOutlierFrames: mean traces");
    plt.tracesComparison([m,m_out],...
        'fps', specs.getFps(), 'nomean', false, 'fw', 0.1);
    
    %%

    subplot(2,1,1);
    hold on;
    plot((0:(length(m_movmean)-1))/specs.getFps(), m_movmean+options.n_sd*m_std, '--', 'color', 'black')
    plot((0:(length(m_movmean)-1))/specs.getFps(), m_movmean-options.n_sd*m_std, '--', 'color', 'black')
    scatter(find(is_outlier)/specs.getFps(), repelem(max(m), n_outliers), 10, [1,0,0], '*')
    hold off;

    legend(["mean trace  - initial", "mean trace - corrected", ...
        "mean+"+string(options.n_sd)+"sd (dt="+string(options.dt)+"s)"], ...
        'location', 'sw', 'FontSize', 8);

    sgtitle([filename, ...
        string(n_outliers)+" outlier frames ("+num2str(n_outliers/length(m),"%.1e")+")"],...
        'interpreter', 'None', 'FontSize', 12)
    %%
 
    disp("movieRemoveOutlierFrames: saving")

    specs_out = copy(specs);
    specs_out.AddToHistory(functionCallStruct({'fullpath_movie', 'options'}));
    %%
    
    rw.h5saveMovie(fullpath_out, M, specs_out);
    saveas(fig_traces, fullfile(options.diagnosticdir, filename_out + "_traces.png"))
    saveas(fig_traces, fullfile(options.diagnosticdir, filename_out + "_traces.fig"))

end
%%

function options = defaultOptions(basepath)
    
    options.n_sd = 5;
    options.dt = 20; %seconds

    options.diagnosticdir = basepath + "\diagnostic\removeOutlierFrames\";
        
    options.outdir = basepath;
    options.skip = true;
end
%%