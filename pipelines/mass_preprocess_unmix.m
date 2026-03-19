
clear; 
close all;
warning on;
if(isempty(gcp('nocreate'))), parpool('Threads'); end 

diary(fullfile("N:\GEVI_Wave\Logs", ...
        strcat(string(datetime('now','Format','yyyyMMddHHmmss')),'_',mfilename(),'.log')));
%%

% recording_names = ...
%     pathspattern("F:\GEVI_Wave\Preprocessed\", ...
%                  "Spontaneous\mv0105\2024031*\meas*", true)';

recording_names = ["Anesthesia\mv3101\20251210\meas"+compose("%02d", 0:17)'; ...
                   "Anesthesia\mv3102\20251210\meas" + compose("%02d", 0:17)'];
%% 

basefolder_converted = "S:\GEVI_Wave\Preprocessed\"; %"S:\GEVI_Wave\Preprocessed\";
basefolder_processing = "T:\GEVI_Wave\Preprocessed\";
basefolder_preprocessed = "F:\GEVI_Wave\Preprocessed\";
basefolder_analysis = "N:\GEVI_Wave\Analysis\";

skip_if_final_exists = true;

channels = ["G","R"];

binning = 8;
maxRAM = 0.1;
unaccounted_hardware_binning = 1; %For old recordings, hardware binning is not accounted for.

shifts0 = [0,0]; %[0,0.5]; % mm, between R and G channel due to cameras misalignment

mouse_state = "transition";% "awake"; %"anesthesia" %"transition";
unmix_time_resolved = false;

crosstalk_matrix =  [[1, 0]; [0.165, 1]];
% 0.080 for ASAP3
% 0.165 for ASAP7y
% 0.095 for old ace recordings seems good - based on m14 visual v1
% 0.141 (?) for older ASAP2s with different filters

frame_range = [50, inf];
%%

MEs_conv = {}; recording_names_error = [];
for i_f = 1:length(recording_names)
    %%
    
    recording_name = recording_names(i_f);
    
    disp(string(i_f)+"/"+string(length(recording_names))+": "+recording_name);
    error_state = false;
    %%

    try
        %%
        
%         skip_if_final_exists = false;
        basefolder_output = basefolder_preprocessed; 
        postfix_in1 = "cG_bin"+string(binning);
        postfix_in2 = "cR_bin"+string(binning);
        pipeline_preprocessing_2xmoco
        %%
    catch ME
        recording_names_error = [recording_names_error, recording_name];
        MEs_conv{length(MEs_conv)+1} = ME;
        warning(recording_name);
        warning(getReport(ME));
    end   

    try
        %%
        
%         skip_if_final_exists = false;
        basefolder_output = basefolder_analysis;  
        postfix_in1 = "cG_bin"+string(binning)+"*_mc";
        postfix_in2 = "cR_bin"+string(binning)+"*_mc_reg";
        pipeline_unmixing
        %%  
    catch ME
        recording_names_error = [recording_names_error, recording_name];
        MEs_conv{length(MEs_conv)+1} = ME;
        warning(recording_name);
        warning(getReport(ME));
    end 
end
%%

diary off;