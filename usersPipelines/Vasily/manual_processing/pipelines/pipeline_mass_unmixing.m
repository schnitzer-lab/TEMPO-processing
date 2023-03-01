
clear; 
close all;
%%



recording_names = ...
    ["Visual\mCtrl13\20210916\meas00\"];
%      "Anesthesia\m43\20230116\meas" + arrayfun(@(n) string(num2str(n, '%02d')), 0:20)';
%       [rw.readlines("N:\GEVI_Wave\filelists\filelist_visual_ctrl_fast.txt")];

postfix_in1 = "cG_bin8_mc";
postfix_in2 = "cR_bin8_mc_reg";
% postfix_in1 = "cG_bin8_reg_moco";
% postfix_in2 = "cR_bin8_reg_moco";

basefolder_preprocessed = "P:\GEVI_Wave\Preprocessed\";
basefolder_processing = "T:\GEVI_Wave\Preprocessed\";
basefolder_output = "N:\GEVI_Wave\Preprocessed\";   

frame_range = [20, inf];

% fullpath_maskManual_forall = "P:\GEVI_Wave\Preprocessed\Anesthesia\m47\20220707\meas18\m47_d220707_s18long-fps142-cG_bin16_reg_moco_cropMovie_maskManual.bmp";

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
