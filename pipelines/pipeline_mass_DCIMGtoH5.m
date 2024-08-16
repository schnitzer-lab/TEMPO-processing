
clear;
close all;
%%

recording_names = ["Spontaneous\m0101\20230815\meas0"+string(0:2), ...
                   "Spontaneous\m0104\20230815\meas0"+string(4:6), ...
                   "Spontaneous\m0105\20230815\meas0"+string(0:3)];
%     [rw.readlines("N:\GEVI_Wave\filelists\filelist_anesthesia_ace.txt")];

channels = ["G","R"];

basefolder_raw = "R:\GEVI_Wave\Raw\"; %"R:\GEVI_Wave\Raw\";% 
basefolder_converted = "S:\GEVI_Wave\Preprocessed\";

binning = 8;
maxRAM = 0.1;
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