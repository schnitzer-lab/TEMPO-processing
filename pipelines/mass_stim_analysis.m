
 
basepath_preprocessed = "F:\GEVI_Wave\Preprocessed\";    
basepath_processing = "T:\GEVI_Wave\Analysis\"; 
basepath_out = "N:\GEVI_Wave\Analysis\";    

folder_ref = "N:\GEVI_Wave\MiceAlignment\";  

fpatternG_in = "*-cG*fr50*_nohemoS_dFF.h5";
fpatternR_in = "*-cR*fr50*_dFF.h5";

%%

% recording_names = ...
%     pathspattern(basepath, ...
%                  "Visual\m48\20210824\meas*", true)';
% readlines("N:\GEVI_Wave\filelists\filelist_visual_asap3.txt")
% recording_names = ["Visual\m48\20210824\meas00"; "Visual\m48\20210824\meas00"];

recording_names = ...
    pathspattern(basepath, ...
                 "Visual\m48\20210824\meas*", true)';

%%


for i_f = 1:length(recording_names)    
    %%
    
%     i_f = 1;
    recording_name = recording_names(i_f);
    %%

    pipeline_stim_analysis
    %%
end