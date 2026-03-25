
% fpatternG_in = "*-cG*fr50*_nohemoS_dFF.h5";
% fpatternR_in = "*-cR*fr50*_dFF.h5";
% 
% basepath_preprocessed = "F:\GEVI_Wave\Preprocessed\";    
% basepath_processing = "T:\GEVI_Wave\Analysis\"; 
% basepath_out = "F:\GEVI_Wave\Analysis\";  
% folder_ref = "N:\GEVI_Wave\MiceAlignment\";  
% 
% recording_name = "Anesthesia\mv3102\20251210\meas05";

%%

folder_in = fullfile(basepath_preprocessed, recording_name);
fullpath_in = fullfile(folder_in, fpatternG_in);
folder_processing = fullfile(basepath_processing, recording_name);
if(~isfolder(folder_processing)), mkdir(folder_processing); end
folder_out = fullfile(basepath_out, recording_name);
if(~isfolder(folder_out)), mkdir(folder_out); end
%%

recording_name_parts = strsplit(recording_name, '\');
files = dir(fullfile(folder_ref, recording_name_parts(2) + "_cG"  + "*.h5"));
if (length(files) > 1)
    error("more than one reference for the mouse " + ...
        recording_name_parts(2) + " in " + folder_ref)
elseif(length(files) < 1)
    error("no reference for the mouse " + ...
        recording_name_parts(2) + " in " + folder_ref)
end
%%

fullpathGdFF = copyFilesForAnalysis(recording_name, ...
    fpatternG_in, "cG_unmixed_dFF.h5", ...
    'basefolder_preprocessed', basepath_preprocessed);

fullpathRdFF = copyFilesForAnalysis(recording_name, ...
    fpatternR_in, "cR_dFF", ...
    'basefolder_preprocessed', basepath_preprocessed);
%%

movieCopyReference(fullpathGdFF, [], 'folder_ref', folder_ref);
movieCopyReference(fullpathRdFF, [], 'folder_ref', folder_ref);

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
