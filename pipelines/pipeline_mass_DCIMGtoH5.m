
clear; 
close all;
warning on;
if(isempty(gcp('nocreate'))), parpool('Threads'); end 

diary(fullfile("P:\GEVI_Wave\Logs", ...
        strcat(string(datetime('now','Format','yyyyMMddHHmmss')),'_',mfilename(),'.log')));
%%


recording_names = ...
    pathspattern("R:\GEVI_Wave\Raw\", "**\*\202505*\meas*", true)';

%     [rw.readlines("N:\GEVI_Wave\filelists\filelist_anesthesia_ace.txt")];
%%

basefolder_raw = "R:\GEVI_Wave\Raw\";% 
basefolder_converted = "S:\GEVI_Wave\Preprocessed\";

channels = ["G","R"];

binning = 8;
maxRAM = 0.5;
unaccounted_hardware_binning = 1; %For old recordings, hardware binning is not accounted for.
%%

MEs = {};
for i_f = 1:length(recording_names)
    recording_name = recording_names(i_f);
    disp(string(i_f)+"/"+string(length(recording_names))+": "+recording_name);
    try
        pipeline_DCIMGtoH5
    catch ME
        MEs{length(MEs)+1} = ME;
        warning(recording_name);
        warning(ME.message);
    end   
end
%%

diary off