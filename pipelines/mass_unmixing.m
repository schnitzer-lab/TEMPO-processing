
clear; 
close all;
warning on;
if(isempty(gcp('nocreate'))), parpool('Threads'); end 

diary(fullfile("P:\GEVI_Wave\Logs", ...
        strcat(string(datetime('now','Format','yyyyMMddHHmmss')),'_',mfilename(),'.log')));
%%

% recording_names = ...
%     pathspattern("\\oak-smb-mschnitz.stanford.edu\groups\mschnitz\michelle\GEVI_Wave\Preprocessed\", ...
%                  "Visual\*mjr\*\meas*", true)';
recording_names = ...
    pathspattern("P:\GEVI_Wave\Preprocessed\", ...
                 "Spontaneous\mv0105\2024031*\meas*", true)';
% recording_names = ...
%     readlines("N:\GEVI_Wave\filelists\filelist_michelle_unprocessed20240715.txt"); 

% recording_names = flip(recording_names);
%%

basefolder_preprocessed = "P:\GEVI_Wave\Preprocessed\";
basefolder_processing = "P:\GEVI_Wave\Preprocessed\";
basefolder_output = "N:\GEVI_Wave\Analysis\";    
%%

skip_if_final_exists = false;

mouse_state = "transition";% "iso"; "awake"; %"anesthesia" "transition"
unmix_time_resolved = true;

crosstalk_matrix =  [[1, 0]; [0.080, 1]];
% % 0.080 for ASAP3
% % 0.165 for ASAP7y
% % 0.095 for old ace recordings seems good - based on m14 visual v1
% % 0.141 (?) for older ASAP2s with different filters

frame_range = [50, inf];

postfix_in1 = "cG_bin8_mc";
postfix_in2 = "cR_bin8_mc_reg";

%%

MEs = {};
for i_f = 1:length(recording_names)
    %%
    recording_name = recording_names(i_f);
    disp(string(i_f)+"/"+string(length(recording_names))+": "+recording_name);
    try
        pipeline_unmixing
    catch ME
        MEs{length(MEs)+1} = {recording_name, ME};
        warning(recording_name);
        warning(ME.message);
    end   
end
%%

diary off
