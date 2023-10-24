
clear;
close all;
%%

recording_names =  ["\Visual\ms2102\20231020\meas"+arrayfun(@(k) string(num2str(k,'%02.f')), 0:1),...
                    "\Visual\ms2103\20231021\meas"+arrayfun(@(k) string(num2str(k,'%02.f')), 0:1)];
%     [rw.readlines("N:\GEVI_Wave\filelists\filelist_anesthesia_ace.txt")];

channels = ["G","R"];

basefolder_raw = "R:\GEVI_Wave\Raw\";
basefolder_converted = "S:\GEVI_Wave\Preprocessed\";
basefolder_processing = "T:\GEVI_Wave\Preprocessed\";
basefolder_preprocessed = "P:\GEVI_Wave\Preprocessed\";
skip_if_final_exists = true;

binning = 8;
maxRAM = 0.1;
unaccounted_hardware_binning = 1; %For old recordings, hardware binning is not accounted for.

shifts0 = [20,0]; % pix, between R and G channel due to cameras misalignment

mouse_state = "awake";% "awake"; %"anesthesia"
crosstalk_matrix =  [[1, 0]; [0.07, 1]]; %[[1, 0]; [0.095, 1]]; %
frame_range = [20, inf];

%%

parpool('Threads');
%%

MEs_conv = {};
for i_f = 1:length(recording_names)
    %%
    recording_name = recording_names(i_f);
    
    disp(string(i_f)+"/"+string(length(recording_names))+": "+recording_name);
    
    try
        channels = ["G","R"];
        pipeline_DCIMGtoH5
    catch ME
        MEs_conv{length(MEs_conv)+1} = ME;
        warning(recording_name);
        warning(getReport(ME));
    end   
    
    try
        basefolder_output = "P:\GEVI_Wave\Preprocessed\";
        postfix_in1 = "cG_bin8";
        postfix_in2 = "cR_bin8";
        pipeline_preprocessing_2xmoco
    catch ME
        MEs_conv{length(MEs_conv)+1} = ME;
        warning(recording_name);
        warning(getReport(ME));
    end   

    try
        basefolder_output = "N:\GEVI_Wave\Analysis\";    
        postfix_in1 = "cG_bin8_mc";
        postfix_in2 = "cR_bin8_mc_reg";
        pipeline_unmixing
    catch ME
        MEs_conv{length(MEs_conv)+1} = ME;
        warning(recording_name);
        warning(getReport(ME));
    end 
end
%%