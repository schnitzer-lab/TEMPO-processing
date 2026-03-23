
clear; 
close all;
warning on;
if(isempty(gcp('nocreate'))), parpool('Threads'); end 

diary(fullfile("N:\GEVI_Wave\Logs", ...
        strcat(string(datetime('now','Format','yyyyMMddHHmmss')),'_',mfilename(),'.log')));
%%

% recording_names = ...
%     pathspattern("F:\GEVI_Wave\Preprocessed\", ...
%                  "Type\m0000\2003030*\meas*", true)';
% readlines("N:\GEVI_Wave\filelists\filelist_type.txt")
recording_names = ["Type\m0000\20030303\meas" + compose("%02d", 0:10)';];
%%

basefolder_converted = "S:\GEVI_Wave\Preprocessed\";
basefolder_preprocessed = "F:\GEVI_Wave\Preprocessed\";
basefolder_processing = "T:\GEVI_Wave\Preprocessed\";
%%

skip_if_final_exists  = true;

postfix_in1 = "cG_bin8";
postfix_in2 = "cR_bin8";

frame_range = [50,Inf];
shifts0 = [0, 0]; % [0, 0.5] mm, between R and G channel due to cameras misalignment

maxRAM = 0.1;
%%

MEs = {}; recording_ids_error = []; recording_ids_skipped = [];
for i_f = 1:length(recording_names)
    
    recording_name = recording_names(i_f);
    displog(string(i_f)+"/"+string(length(recording_names))+": "+recording_name);
    %%

    try 
        pipeline_preprocessing_2xmoco
        %%
    catch ME
        MEs{length(MEs)+1} = {recording_name, ME};
        if(~contains(ME.message, "Final file exists, ending"))
            warning("Failed " + recording_name + ": "+ ME.message);
            recording_ids_error = [recording_ids_error, i_f];            
        else
            displog("Skipped " + recording_name+": "+ ME.message)
            recording_ids_skipped = [recording_ids_skipped, i_f];
        end
    end   
end
%%

diary off
    