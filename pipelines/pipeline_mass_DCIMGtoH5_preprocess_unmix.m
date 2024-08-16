
% clear;
close all;
%%

basefolder_raw = "O:\michelle\V\GEVI_Wave\Raw\"; %"\\VoltageRaw\DCIMG\GEVI_Wave\Raw\"; 

files = [dir(basefolder_raw + "\Visual\*mjr\2024*\meas*")]; %dir(basefolder_raw + "Visual\m40\20210824\meas00\");
recording_names = arrayfun(@(f) string(fullfile(f.folder, f.name)), files);
recording_names = erase(recording_names, basefolder_raw);



%  recording_names = ...[rw.readlines("N:\GEVI_Wave\filelists\filelist_loco_canula.txt")]; 
%  ["Visual\m40\20210824\meas00";];
%  "\Visual\ms2103\20231021\meas"+arrayfun(@(k) string(num2str(k,'%02.f')), 0:1)];


channels = ["G","R"];

% basefolder_raw = "\\VoltageRaw\DCIMG\GEVI_Wave\Raw\"; %"R:\GEVI_Wave\Raw\";% "M:\Raw Data Files\Raw\"; %%
basefolder_converted = "O:\michelle\V\GEVI_Wave\Preprocessed\"; %"S:\GEVI_Wave\Preprocessed\";
basefolder_processing = "T:\GEVI_Wave\Preprocessed\";
basefolder_preprocessed = "O:\michelle\V\GEVI_Wave\Preprocessed\"; %"P:\GEVI_Wave\Preprocessed\";
basefolder_analysis = "N:\GEVI_Wave\Analysis\";
skip_if_final_exists = true;

binning = 8;
maxRAM = 0.1;
unaccounted_hardware_binning = 1; %For old recordings, hardware binning is not accounted for.

shifts0 = [0,0]; %[20,0]; % pix, between R and G channel due to cameras misalignment

mouse_state = "awake";% "awake"; %"anesthesia" %"transition";
crosstalk_matrix =  [[1, 0]; [0.07, 1]]; %[[1, 0]; [0.095, 1]]; %
frame_range = [50, inf];

%%

parpool('Threads');
%%

MEs_conv = {};
for i_f = 1:length(recording_names)
    %%
    recording_name = recording_names(i_f);
    
    disp(string(i_f)+"/"+string(length(recording_names))+": "+recording_name);
    
    try
        %%
        
        channels = ["G","R"];
%         skip_if_final_exists = true;
        pipeline_DCIMGtoH5
        %%
    catch ME
        MEs_conv{length(MEs_conv)+1} = ME;
        warning(recording_name);
        warning(getReport(ME));
    end   
    
    try
        %%
        
        basefolder_output = basefolder_preprocessed; 
        postfix_in1 = "cG_bin"+string(binning);
        postfix_in2 = "cR_bin"+string(binning);
        pipeline_preprocessing_2xmoco
        %%
    catch ME
        MEs_conv{length(MEs_conv)+1} = ME;
        warning(recording_name);
        warning(getReport(ME));
    end   

    try
        %%
        
        basefolder_output = basefolder_analysis;  
        postfix_in1 = "cG_bin"+string(binning)+"_mc";
        postfix_in2 = "cR_bin"+string(binning)+"_mc_reg";
%         skip_if_final_exists = false;
        pipeline_unmixing
        %%  
    catch ME
        MEs_conv{length(MEs_conv)+1} = ME;
        warning(recording_name);
        warning(getReport(ME));
    end 
end
%%