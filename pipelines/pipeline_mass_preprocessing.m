
clear;
close all;
%%

recording_names =  ["Spontaneous\mv0105\20230815\meas0"+string(0:3)];

skip_if_final_exists  = true;

postfix_in1 = "cG_bin8";
postfix_in2 = "cR_bin8";
    
basefolder_converted = "S:\GEVI_Wave\Preprocessed\";
basefolder_processing = "T:\GEVI_Wave\Preprocessed\";
basefolder_output = "P:\GEVI_Wave\Preprocessed\";

shifts0 = [20,0]; % pix, between R and G channel due to cameras misalignment

maxRAM = 0.1;
% parpool('Threads');
%%

MEs = {};
for i_f = 1:length(recording_names)

    recording_name = recording_names(i_f);
    disp(string(i_f)+"/"+string(length(recording_names))+": "+recording_name);

    try 
        pipeline_preprocessing_2xmoco
    catch ME
        MEs{length(MEs)+1} = {recording_name, ME};
        warning(recording_name);
        warning(ME.message);
    end
end
    