
clear; 
close all;
%%


%use proper decrosstalking for ace!
recording_names =  [
    "Anesthesia\m16\20210628\meas00",...
    "Anesthesia\m4\20200626\meas00",...
    "Anesthesia\m5\20200626\meas00",...
    "Anesthesia\m10\20200821\meas00",...
    "Anesthesia\m13\20210628\meas00",...
    "Anesthesia\m7\20210420\meas00",...
    "Anesthesia\m11\20201013\meas02",...
    "Anesthesia\m11\20201013\meas03",...
    "Anesthesia\m11\20201013\meas04",...
    "Anesthesia\m11\20201013\meas05",...
    "Anesthesia\m11\20201013\meas06",...
    "Anesthesia\m11\20201013\meas07",...
    "Anesthesia\m11\20201013\meas08"];
%       [rw.readlines("N:\GEVI_Wave\filelists\filelist_visual_ctrl_fast.txt")];

postfix_in1 = "cG_bin8_mc";
postfix_in2 = "cR_bin8_mc_reg";

mouse_state = "anesthesia";
skip_if_final_exists = false;

basefolder_preprocessed = "P:\GEVI_Wave\Preprocessed\";
basefolder_processing = "T:\GEVI_Wave\Preprocessed\";
basefolder_output = "N:\GEVI_Wave\Analysis\";    

crosstalk_matrix =  [[1, 0]; [0.095, 1]]; %0.066 [[1, 0]; [0, 1]];
% i used to use 0.079 for newer ASAP3 but 0.65-0.68 seems to work much better; 
% 0.1 for older ASAP2s with different filters 
% 0.09 for very old ace recordings seems good - based on m14 visual v1
% not sure this is correct, but it works for ASAP3 recordings
frame_range = [20, inf];

% parpool('Threads');
%%

MEs = {};
for i_f = 1:length(recording_names)
    recording_name = recording_names(i_f);
    disp(string(i_f)+"/"+string(length(recording_names))+": "+recording_name);
    try
        pipeline_unmixing
    catch ME
        MEs{length(MEs)+1} = ME;
        warning(recording_name);
        warning(ME.message);
    end   
end
