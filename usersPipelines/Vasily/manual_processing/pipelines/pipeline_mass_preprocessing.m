
clear;
close all;
%%

recording_names = ...
    ["Visual\mCtrl13\20210916\meas00\"];
%      "Anesthesia\m43\20230116\meas" + arrayfun(@(n) string(num2str(n, '%02d')), 0:20)';
%       [rw.readlines("N:\GEVI_Wave\filelists\filelist_visual_ctrl_slow.txt")];

channels = ["G","R"];
 
% basefolder_raw = "R:\GEVI_Wave\Raw\"; %
basefolder_raw = "\\VoltageRaw\DCIMG\GEVI_Wave\Raw\"; %
basefolder_converted = "S:\GEVI_Wave\Preprocessed\";
basefolder_processing = "T:\GEVI_Wave\Preprocessed\";
basefolder_output = "P:\GEVI_Wave\Preprocessed\";

binning = 8;
maxRAM = 0.1;
unaccounted_hardware_binning = 1; %For old recordings, hardware binning is not accounted for.

% parpool('Threads');
%%

MEs = {};
for i_f = 1:length(recording_names)
    close all
    recording_name = recording_names(i_f);
    disp(string(i_f)+"/"+string(length(recording_names))+": "+recording_name);

    try 
        pipeline_preprocessing_2xmoco
    catch ME
        MEs{length(MEs)+1} = ME;
        warning(recording_name);
        warning(ME.message);
    end
end
    