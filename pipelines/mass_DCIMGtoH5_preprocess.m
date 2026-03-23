
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

basefolder_raw =  "F:\GEVI_Wave\Raw\";% 
basefolder_converted = "S:\GEVI_Wave\Preprocessed\";
basefolder_preprocessed = "F:\GEVI_Wave\Preprocessed\";
basefolder_processing = "T:\GEVI_Wave\Preprocessed\";

channels = ["G","R"];

binning = 8;
maxRAM = 0.1;
unaccounted_hardware_binning = 1; %For old recordings, hardware binning is not accounted for.

frame_range = [50,Inf];
shifts0 = [0,0]; % [0,0.5] mm
%%

MEs = {}; recording_ids_error = []; recording_ids_skipped = [];
for i_f = 1:length(recording_names)
    
    recording_name = recording_names(i_f);
    displog(string(i_f)+"/"+string(length(recording_names))+": "+recording_name);
    %%
    try        

        pipeline_DCIMGtoH5 
        %%
    catch ME
        MEs{length(MEs)+1} = {recording_name, ME};
        if(~contains(ME.message, "Final file exists, ending"))
            warning("Failed " + recording_name + ": "+ ME.message);
            recording_ids_error = [recording_ids_error, i_f];   
            continue;
        else
            displog("Skipped " + recording_name+": "+ ME.message)
            recording_ids_skipped = [recording_ids_skipped, i_f];
        end        
    end 

    %%
    try        

        % skip_if_final_exists = false;
        postfix_in1 = "cG_bin"+string(binning);
        postfix_in2 = "cR_bin"+string(binning);
        
        pipeline_preprocessing_2xmoco    
        %%
    catch ME
        MEs{length(MEs)+1} = {recording_name, ME};
        if(~contains(ME.message, "Final file exists, ending"))
            warning("Failed " + recording_name + ": "+ ME.message);
            recording_ids_error = [recording_ids_error, i_f];   
            continue;
        else
            displog("Skipped " + recording_name+": "+ ME.message)
            recording_ids_skipped = [recording_ids_skipped, i_f];
        end        
    end 
end
%%

diary off

    