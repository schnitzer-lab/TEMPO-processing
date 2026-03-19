
clear; 
close all;
warning on;
if(isempty(gcp('nocreate'))), parpool('Threads'); end 

diary(fullfile("N:\GEVI_Wave\Logs", ...
        strcat(string(datetime('now','Format','yyyyMMddHHmmss')),'_',mfilename(),'.log')));
%%

% recording_names = ...
%     pathspattern("F:\GEVI_Wave\Preprocessed\", ...
%                  "Visual\mv31*\20251120\meas*", true)';

recording_names = [...
     readlines("N:\GEVI_Wave\filelists\filelist_anesthesia_asap3.txt"); ...
     readlines("N:\GEVI_Wave\filelists\filelis_anesthesia_transition_asap3.txt"); ...
     readlines("N:\GEVI_Wave\filelists\filelist_sleep_asap3.txt"); ...
     readlines("N:\GEVI_Wave\filelists\filelist_sleep_asap5.txt")]; 
recording_names = flip(recording_names);
%%

basefolder_preprocessed = "F:\GEVI_Wave\Preprocessed\";
basefolder_processing = "T:\GEVI_Wave\Preprocessed\";
% basefolder_output = "N:\GEVI_Wave\Analysis\"; % "N:\GEVI_Wave\Analysis\";    
%%

skip_if_final_exists = true;

mouse_state = "transition";% "iso"; "awake"; %"anesthesia" "transition"
unmix_time_resolved = false;

crosstalk_matrix =  [[1, 0]; [0.080, 1]];
% % 0.080 for ASAP3
% % 0.165 for ASAP7y
% % 0.095 for old ace recordings seems good - based on m14 visual v1
% % 0.141 (?) for older ASAP2s with different filters

frame_range = [50, inf];

postfix_in1 = "cG_bin8_mc";
postfix_in2 = "cR_bin8_mc_reg";

%%

MEs = {}; recording_names_error = [];
for i_f = 1:length(recording_names)
    %%
    recording_name = recording_names(i_f);
    disp(string(i_f)+"/"+string(length(recording_names))+": "+recording_name);
    try
        pipeline_unmixing
    catch ME
        recording_names_error = [recording_names_error, recording_name];
        MEs{length(MEs)+1} = {recording_name, ME};
        warning(recording_name);
        warning(ME.message);
    end   
end
%%

diary off
