
clear;
close all;
%%

files = dir("\\Bfm\b\Visual\mEndo*\**\meas*");
recording_names = arrayfun(@(f) string(fullfile(f.folder, f.name)), files);
recording_names = erase(recording_names, "\\Bfm\b\");
%%
% recording_names =  ["\Anesthesia\mv0105\20230831\meas"+arrayfun(@(k) string(num2str(k,'%02.f')), 0:30)];
%     [rw.readlines("N:\GEVI_Wave\filelists\filelist_anesthesia_ace.txt")];

channels = ["G","R"];

basefolder_raw = "\\Bfm\b\Visual\"; %"R:\GEVI_Wave\Raw\";% "M:\Raw Data Files\Raw\"; %
basefolder_converted = "S:\GEVI_Wave\Preprocessed\";
basefolder_processing = "T:\GEVI_Wave\Preprocessed\";
basefolder_output = "P:\GEVI_Wave\Preprocessed\";

binning = 4;
maxRAM = 0.1;
unaccounted_hardware_binning = 1; %For old recordings, hardware binning is not accounted for.

shifts0 = [0,0];

% parpool('Threads');
%%

MEs_conv = {};
for i_f = 1:length(recording_names)
    recording_name = recording_names(i_f);
    disp(string(i_f)+"/"+string(length(recording_names))+": "+recording_name);
    try
        pipeline_DCIMGtoH5
    catch ME
        MEs_conv{length(MEs_conv)+1} = ME;
        warning(recording_name);
        warning(ME.message);
    end   
end
%%

postfix_in1 = "cG_bin4";
postfix_in2 = "cR_bin4";

skip_if_final_exists  = true;

MEs_pp = {};
for i_f = 1:length(recording_names)

    recording_name = recording_names(i_f);
    disp(string(i_f)+"/"+string(length(recording_names))+": "+recording_name);

    try 
        pipeline_preprocessing_2xmoco
    catch ME
        MEs_pp{length(MEs_pp)+1} = {recording_name, ME};
        warning(recording_name);
        warning(ME.message);
    end
end
%%


    