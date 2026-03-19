% 
clear; 
close all;
warning on;
if(isempty(gcp('nocreate'))), parpool('Threads'); end 

diary(fullfile("N:\GEVI_Wave\Logs", ...
        strcat(string(datetime('now','Format','yyyyMMddHHmmss')),'_',mfilename(),'.log')));
%%


% recording_names = ...
%     pathspattern("Z:\GEVI_Wave\Raw\", "*\*\*\meas*", true)';

recording_names = ["Anesthesia\mv3101\20251210\meas"+compose("%02d", 0:17)'; ...
                   "Anesthesia\mv3102\20251210\meas" + compose("%02d", 0:17)'];
%%

basefolder_raw = "B:\GEVI_Wave\Raw";
basefolder_converted = "S:\GEVI_Wave\Preprocessed\";

channels = ["G","R"];

binning = 8;
maxRAM = 0.5;
unaccounted_hardware_binning = 1; %For old recordings, hardware binning is not accounted for.
%%

MEs = {}; recording_names_error = [];
for i_f = 1:length(recording_names)
    %%
    recording_name = recording_names(i_f);
    displog(string(i_f)+"/"+string(length(recording_names))+": "+recording_name);
    try
        pipeline_DCIMGtoH5
    catch ME
        recording_names_error = [recording_names_error, recording_name];
        MEs{length(MEs)+1} = ME;
        warning(recording_name);
        warning(ME.message);
    end   
end
%%

diary off