function fullpath_out = movieTrialAverage(fullpath_movie, varargin)
    
    [basepath, filename, ext, basefilename, channel, postfix] = ...
        filenameParts(fullpath_movie);

    options = defaultOptions(basepath);
    if(~isempty(varargin))
        options = getOptions(options, varargin);
    end
    %%
    
    if (~isfolder(options.outdir)) mkdir(options.outdir); end
    if (~isfolder(options.illustrdir)) mkdir(options.illustrdir); end
    if (~isfolder(options.diagnosticdir)) mkdir(options.diagnosticdir); end

    filename_out = basefilename+channel+postfix+options.postfix_new;
    fullpath_out = fullfile(options.outdir, filename_out + ext);
    
    if (isfile(fullpath_out))
        if(options.skip)
            disp("movieTrialAverage: Output file exists. Skipping: " + fullpath_out)
            return;
        else
            warning("movieTrialAverage: Output file exists. Deleting: " + fullpath_out);
            delete(fullpath_out);
        end     
    end
    %%
    
    disp("movieTrialAverage: reading movie")

    [M,specs] = rw.h5readMovie(fullfile(basepath, filename + ".h5"));
    ttl_signal = specs.getTTLTrace(size(M,3));
    %%
    
    disp("movieTrialAverage: rearranging movie into trials")

    [M_stim, window_stim, intervals_stim] = signalTrials(M, ttl_signal, ...
        'drop', options.drop, 'iti_scale', options.iti_scale,...
        'align_to_end', options.align_to=="offset");
    M_stim_av = squeeze(mean(M_stim, 1));
    
    % plt.SliderMovie(plt.saturate(M_stim_av.*nan_mask, 0.0))
    %%
    
    disp("movieTrialAverage: rearranging timestamps_table into trials")
    specs_out = copy(specs);
    specs_out.AddToHistory("movieTrialAverage");
    
    timestamps_table = specs_out.extra_specs('timestamps_table');
    timestamps_table = timestamps_table(specs_out.timeorigin:(specs_out.timeorigin + size(M,3)-1),:);
    [timestamps_table_stim, ~, ~] = signalTrials(timestamps_table', ttl_signal, ...
        'drop', 2, 'iti_scale', 0.75, 'align_to_end', options.align_to=="offset");
    timestamps_table_stim_av = squeeze(mean(timestamps_table_stim,1))';
    timestamps_table_stim_av = [NaN(specs_out.timeorigin-1, size(timestamps_table_stim_av,2)); ...
                                timestamps_table_stim_av]; 
    specs_out.extra_specs('timestamps_table') = timestamps_table_stim_av;
    %%

    disp("movieTrialAverage: plotting illustrations")
    
    m = squeeze(mean(M, [1,2], 'omitnan'));

    fig_in = plt.getFigureByName("movieTrialAverage: input");
    plt.tracesComparison([...
        ttl_signal*std(m)/std(ttl_signal), ...
        squeeze(mean(M, [1,2], 'omitnan'))], ...
        'fps', specs.getFps(), 'fw', 0.2, 'spacebysd', 3, 'labels', ["ttl", "mean"])
    sgtitle(filename, 'interpreter', 'none')

    m_stim_av = squeeze(mean(M_stim_av, [1,2], 'omitnan'));
    ttl_signal_stim_av = specs_out.getTTLTrace(length(m_stim_av)); 

    fig_av = plt.getFigureByName("movieTrialAverage: averaged");
    plot([ttl_signal_stim_av*std(m_stim_av)/std(ttl_signal_stim_av), m_stim_av])
    title(filename_out, 'interpreter', 'none')
    %%
    
    disp("movieTrialAverage: saving")
    
    rw.h5saveMovie(fullpath_out, M_stim_av, specs_out);
    saveas(fig_in, fullfile(options.diagnosticdir, filename_out + "_in.png"))
    saveas(fig_in, fullfile(options.diagnosticdir, filename_out + "_in.fig"))
    saveas(fig_av, fullfile(options.diagnosticdir, filename_out + "_av.png"))
    saveas(fig_av, fullfile(options.diagnosticdir, filename_out + "_av.fig"))

end
%%

function options = defaultOptions(basepath)
    
    options.diagnosticdir = basepath + "\diagnostic\movieTrialAverage\";
    options.illustrdir = basepath + "\illustrations\";

    options.drop = 2;
    options.iti_scale = 0.75;
    options.align_to = "offset"; % "onset" or "offset"

    options.outdir = basepath;
    options.postfix_new = "_trialAv";
    options.skip = true;
end
%%