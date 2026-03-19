
clear; 
close all;
warning on;
if(isempty(gcp('nocreate'))), parpool('Threads'); end 

diary(fullfile("N:\GEVI_Wave\Logs", ...
        strcat(string(datetime('now','Format','yyyyMMddHHmmss')),'_',mfilename(),'.log')));
%%

% recording_names =  ...
%     rw.readlines("N:\GEVI_Wave\filelists\filelis_anesthesia_transition_asap3.txt");

recording_names = ...
    pathspattern("F:\GEVI_Wave\Preprocessed\", "\Iso*\*\**\meas*", true)';
%%

basefolder_converted = "S:\GEVI_Wave\Preprocessed\";
basefolder_processing = "T:\GEVI_Wave\Preprocessed\";
basefolder_output = "F:\GEVI_Wave\Preprocessed\";
%%

skip_if_final_exists  = false;

postfix_in1 = "cG_bin8";
postfix_in2 = "cR_bin8";
    
shifts0 = [0, 0]; % [0, 0.5] mm, between R and G channel due to cameras misalignment

maxRAM = 0.1;
%%

MEs = {}; recording_names_error = [];
for i_f = 1:length(recording_names)

    recording_name = recording_names(i_f);
    displog(string(i_f)+"/"+string(length(recording_names))+": "+recording_name);

    try 
        pipeline_preprocessing_2xmoco
    catch ME
        recording_names_error = [recording_names_error, recording_name];
        MEs{length(MEs)+1} = {recording_name, ME};
        warning(recording_name);
        warning(ME.message);
    end
end
%%

diary off
    