
% clear;
close all;
%%

basefolder_analysis = "N:\GEVI_Wave\Analysis\";
files = [dir(basefolder_analysis + "\Visual\*mjr\*\meas*")]; %dir(basefolder_raw + "Visual\m40\20210824\meas00\");
recording_names = arrayfun(@(f) string(fullfile(f.folder, f.name)), files);
recording_names = erase(recording_names, basefolder_analysis);
% recording_names = flip(recording_names)

channels = ["G","R"];

%%

MEs_conv = {};
for i_f = 1:length(recording_names)
    %%
    recording_name = recording_names(i_f);
    
    disp(string(i_f)+"/"+string(length(recording_names))+": "+recording_name);
   
    try
        %%
        postfix_in1 = "cG_unmixed_dFF";
        postfix_in2 = "cR_dFF";
        fullpath1 = fullfile(basefolder_analysis, recording_name, postfix_in1 + ".h5");
        fullpath2 = fullfile(basefolder_analysis, recording_name, postfix_in2 + ".h5");
        
        moviesCopyReference(fullpath1, []);
        moviesCopyReference(fullpath2, []);
        
        movieSavePreviewVideos(fullpath1, 'skip', true, 'mask', true)
        movieSavePreviewVideos(fullpath2, 'skip', true, 'mask', true)
        
        regions = {"RSP", "V1", [4,8,12,14,16,20]};
        fullpats_regions1 = movieExtractRegionTrace(fullpath1, regions);
        fullpats_regions2 = movieExtractRegionTrace(fullpath2, {"V1"});
        
        for(fp = fullpats_regions1) moviePlotTraceStim(fp, "mean"); end
        for(fp = fullpats_regions2) moviePlotTraceStim(fp, "mean"); end
        
        %%  
    catch ME
        MEs_conv{length(MEs_conv)+1} = ME;
        warning(recording_name);
        warning(getReport(ME));
    end 
end
%%