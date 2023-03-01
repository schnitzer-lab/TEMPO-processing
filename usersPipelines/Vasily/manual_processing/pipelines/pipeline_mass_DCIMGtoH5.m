
clear;
close all;
%%

recording_names = [...
    "Visual\m14\20210322\meas00"];...
%      [rw.readlines("N:\GEVI_Wave\filelists\filelist_visual_asap3.txt")];


binning = 8;
maxRAM = 0.1;
unaccounted_hardware_binning = 1; %For old recordings, hardware binning is not accounted for.

basefolder_raw = "\\VoltageRaw\DCIMG\GEVI_Wave\Raw\";
basefolder_converted = "S:\GEVI_Wave\Preprocessed\";

channels = ["G","R"];
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