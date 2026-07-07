
clear; 
close all;
warning on;
if(isempty(gcp('nocreate'))), parpool('Threads'); end 

diary(fullfile("N:\GEVI_Wave\Logs", ...
        strcat(string(datetime('now','Format','yyyyMMddHHmmss')),'_',mfilename(),'.log')));
%%

% recording_names = ...
%     pathspattern("F:\GEVI_Wave\Preprocessed\", ...
%                  "Visual\m48\20210824\meas*", true)';
% readlines("N:\GEVI_Wave\filelists\filelist_visual_asap3.txt")
recording_names = ["Visual\m48\20210824\meas00"; "Visual\m48\20210824\meas00"];
%%

basefolder_preprocessed = "F:\GEVI_Wave\Preprocessed\";
basefolder_processing = "T:\GEVI_Wave\Preprocessed\";  
%%

skip_if_final_exists = true;

mouse_state = "transition";% "iso"; "awake"; %"anesthesia" "transition"
unmix_time_resolved = false;

crosstalk_matrix =  [[1, 0]; [0.072, 1]];
% 0.072 for ASAP3 / ASAP5
% 0.165 for ASAP7y
% 0.095 for old ace recordings seems good - based on m14 visual v1
% 0.141 (?) for older ASAP2s with different filters

postfix_in1 = "cG_bin8*_mc";
postfix_in2 = "cR_bin8*_mc_reg";
%%

MEs = {}; recording_ids_error = []; recording_ids_skipped = [];
for i_f = 1:length(recording_names)
    
    recording_name = recording_names(i_f);
    displog(string(i_f)+"/"+string(length(recording_names))+": "+recording_name);
    %%
    try
        pipeline_unmixing
        %%
    catch ME
        if(~contains(ME.message, "Final file exists, ending"))
            warning("Failed " + recording_name + ": "+ ME.message);
            recording_ids_error = [recording_ids_error, i_f]; 
            MEs{length(MEs)+1} = {recording_name, ME};           
        else
            displog("Skipped " + recording_name+": "+ ME.message)
            recording_ids_skipped = [recording_ids_skipped, i_f];
        end
    end   
end
%%

diary off
