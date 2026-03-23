
clear; 
close all;
warning on;
if(isempty(gcp('nocreate'))), parpool('Threads'); end 

diary(fullfile("N:\GEVI_Wave\Logs", ...
        strcat(string(datetime('now','Format','yyyyMMddHHmmss')),'_',mfilename(),'.log')));
%%

recording_names = "Isofluorane\mv0108\20251026\meas0" + string(0:9)';
% recording_names = ...
%     pathspattern("R:\GEVI_Wave\Raw\", "**\*\202505*\meas*", true)';
% recording_names = ["Spontaneous\mDLRKlMORcre001\20240912\meas00", ...
%                    "Spontaneous\mRArchLKl001\20240912\meas00"];
%%

basefolder_raw =  "R:\GEVI_Wave\Raw\";% 
basefolder_converted = "S:\GEVI_Wave\Preprocessed\";
basefolder_processing = "T:\GEVI_Wave\Preprocessed\";
basefolder_output = "F:\GEVI_Wave\Preprocessed\";

channels = ["G","R"];

binning = 8;
maxRAM = 0.1;
unaccounted_hardware_binning = 1; %For old recordings, hardware binning is not accounted for.

frame_range = [50,Inf];
shifts0 = [0,0]; % [0,0.5] mm
%%

MEs_conv = {}; recording_ids_error_conv = []; recording_ids_skipped_conv = [];
for i_f = 1:length(recording_names)
    %%

    recording_name = recording_names(i_f);
    displog(string(i_f)+"/"+string(length(recording_names))+": "+recording_name);
    try
        pipeline_DCIMGtoH5
    catch ME
        MEs_conv{length(MEs_conv)+1} = {recording_name, ME};
        if(~contains(ME.message, "Final file exists, ending"))
            warning("Failed " + recording_name + ": "+ ME.message);
            recording_ids_error_conv = [recording_ids_error_conv, i_f];            
        else
            displog("Skipped " + recording_name+": "+ ME.message)
            recording_ids_skipped_conv = [recording_ids_skipped_conv, i_f];
        end
    end   
end
%%

postfix_in1 = "cG_bin8";
postfix_in2 = "cR_bin8";

skip_if_final_exists  = true;
%%

MEs_pp = {}; recording_ids_error_pp = []; recording_ids_skipped_pp = [];
for i_f = 1:length(recording_names)
    
    recording_name = recording_names(i_f);
    displog(string(i_f)+"/"+string(length(recording_names))+": "+recording_name);
    %%
    try
        pipeline_preprocessing_2xmoco
        %%
    catch ME
        MEs_pp{length(MEs_pp)+1} = {recording_name, ME};
        if(~contains(ME.message, "Final file exists, ending"))
            warning("Failed " + recording_name + ": "+ ME.message);
            recording_ids_error_pp = [recording_ids_error_pp, i_f];            
        else
            displog("Skipped " + recording_name+": "+ ME.message)
            recording_ids_skipped_pp = [recording_ids_skipped_pp, i_f];
        end
    end   
end
%%

diary off

    