
basepath = "N:\GEVI_Wave\Analysis";

files = dir(fullfile(basepath, "\Visual\mEndo*\**\meas*"));
recording_names = arrayfun(@(f) string(fullfile(f.folder, f.name)), files);
recording_names = erase(recording_names, basepath);
%%
for i_f = 1:length(recording_names)    
    %%
    
%     i_f = 1;
    recording_name = recording_names(i_f);
    %%

    fullpathGdFF = fullfile(basepath, recording_name, "cG_unmixed_dFF.h5");
    fullpathRdFF = fullfile(basepath, recording_name, "cR_dFF.h5");
    %%

    moviePlotTraceStim(fullpathGdFF, "mean");
    moviePlotTraceStim(fullpathRdFF, "mean");
    %%

    fullpathGdFF = movieTrialAverage(fullpathGdFF);
    fullpathRdFF = movieTrialAverage(fullpathRdFF);
    %%

    nframes = rw.h5getDatasetSize(fullpathGdFF, '/mov', 3);
    specs = rw.h5readMovieSpecs(fullpathGdFF);

    nseconds = floor(nframes/specs.getFps()*10)/10;
    %%

    moviesSavePreviewVideos([fullpathGdFF, fullpathRdFF], 'titles', ...
        ["G umx dFF", "R dFF"], 'nseconds', nseconds)
    %%
end