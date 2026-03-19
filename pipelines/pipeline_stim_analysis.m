
basepath = "T:\GEVI_Wave\Analysis\Anesthesia\";

files = dir(fullfile(basepath, "\mv3101\20251210\meas1*"));
recording_names = arrayfun(@(f) string(fullfile(f.folder, f.name)), files);
recording_names = erase(recording_names, basepath);
%%


for i_f = 1:length(recording_names)    
    %%
    
%     i_f = 1;
    recording_name = recording_names(i_f);
    %%

    fullpathGdFF = fullfile(basepath, recording_name, "cG_unmixedTR_dFF.h5");
    fullpathRdFF = fullfile(basepath, recording_name, "cR_dFF.h5");
    %%
    
    movieCopyReference(fullpathGdFF, [], 'folder_ref', "N:\GEVI_Wave\MiceAlignment\");
    movieCopyReference(fullpathRdFF, [], 'folder_ref', "N:\GEVI_Wave\MiceAlignment\");

    movieSavePreviewVideos(fullpathGdFF, 'skip', false, 'mask', true)
    %%
        
    regions = {"RSP", "V1", [4,8,10,12,14,16,20]};
    fullpats_regions = movieExtractRegionTrace(fullpathGdFF, regions);
    %%

    movieMeanTraces(fullpats_regions, 'space', true);
    %%

    moviePlotTraceStim(fullpats_regions(2), "mean");
    %%
    
    fullpathG_trialav = movieTrialAverage(fullpathGdFF);
    fullpathR_trialav = movieTrialAverage(fullpathRdFF);    
    %%
    
    nframes = rw.h5getDatasetSize(fullpathG_trialav, '/mov', 3);
    specs = rw.h5readMovieSpecs(fullpathG_trialav);
    
    nseconds = floor(nframes/specs.getFps()*10)/10;
    
    moviesSavePreviewVideos([fullpathG_trialav, fullpathR_trialav], 'titles', ...
        ["G umx dFF", "R dFF"], 'nseconds', nseconds)
    %%
end