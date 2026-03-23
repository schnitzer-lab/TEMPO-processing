   
% clear; 
% close all;
% warning on;
% if(isempty(gcp('nocreate'))), parpool('Threads'); end 
% 
% diary(fullfile( ...
%         "N:\GEVI_Wave\Logs", ...
%         strcat(string(datetime('now','Format','yyyyMMddHHmmss')),'_',mfilename(),'.log')));
%%
% 
% recording_name = "Visual\rfm002mjr\20231209\meas00";%"Spontaneous\mv0104\20230815\meas04" %(short 22s recording for tests);
% postfix_in1 = "cG_bin8";
% postfix_in2 = "cR_bin8";
% 
% basefolder_converted = "O:\GEVI_Wave\Preprocessed\";
% basefolder_processing = "T:\GEVI_Wave\Preprocessed\";
% basefolder_output = "F:\GEVI_Wave\Preprocessed\";
% 
% frame_range = [1,Inf];
% shifts0 = [0,0]; %[0,0.5]; % mm, between R and G channel due to cameras misalignment
% 
% maxRAM = 0.1;
% skip_if_final_exists = false;
%%

folder_converted = fullfile(basefolder_converted, recording_name);
folder_processing = fullfile(basefolder_processing, recording_name);
folder_output = fullfile(basefolder_output, recording_name);
%%

file1 = dir(fullfile(folder_converted, "/*" + postfix_in1 + ".h5"));
file2 = dir(fullfile(folder_converted, "/*" + postfix_in2 + ".h5"));

if(isempty(file1)) 
    error("Preprocessing:fileNotFound", "Green channel .h5 file not found")
elseif isempty(file2)
    error("Preprocessing:fileNotFound", "Red channel .h5 file not found")
end
%%               

fullpathGconv = fullfile(file1.folder, file1.name);
fullpathRconv = fullfile(file2.folder, file2.name);

[~, ~, ext1, basefilename1, channel1, ~] = filenameParts(fullpathGconv);
fullpathGin = fullfile(folder_processing, file1.name);
[~, ~, ext2, basefilename2, channel2, ~] = filenameParts(fullpathRconv);
fullpathRin = fullfile(folder_processing, file2.name);
%%

[filedir, filename, fileext, basefilename, channel, ~] = filenameParts(fullpathRconv);
final_file = fullfile(folder_output, filename + "*_mc_reg.h5");
result = dir(final_file);
if(~isempty(result)) 
    if(skip_if_final_exists)
        error("Final file exists, ending " + fullfile(result.folder, result.name)); 
    else
        warning("Final file exists and will be owerwritten " + fullfile(result.folder, result.name)); 
    end
end
%%

if(~strcmp(folder_converted, folder_processing))
    displog("copying data to: "+folder_processing)
    if(~isfolder(folder_processing)), mkdir(folder_processing); end
    if(~isfile(fullpathGin)), copyfile(fullpathGconv,  fullpathGin); end
    if(~isfile(fullpathRin)), copyfile(fullpathRconv,  fullpathRin); end
    copyfile(fullfile(folder_converted, "LVMeta"),  fullfile(folder_processing,"LVMeta"))
    copyfile(fullfile(folder_converted, "processing"),  fullfile(folder_processing,"processing"))
end
%%

fullpaths_mean = movieMeanTraces([string(fullpathGin), string(fullpathRin)]);
    
movieMeanTraceSpectrogram(fullpaths_mean(2), 'frange', [2, Inf], 'timewindow', 5, 'fw', 0.75, ...
    'processingdir', fullfile(folder_converted, "\processing\meanTraceSpectrogram\"));
movieMeanTraceSpectrogram(fullpaths_mean(1), 'frange', [2, Inf], 'timewindow', 5, 'fw', 0.75, ...
    'processingdir', fullfile(folder_converted, "\processing\meanTraceSpectrogram\"));
%%

fullpathGex = movieExtractFrames(fullpathGin, frame_range);
fullpathRex = movieExtractFrames(fullpathRin, frame_range);
%%

[h5path1_mc, shiftsfile1] = movieSimpleMoco(fullpathGex);
[h5path2_mc, shiftsfile2] = movieSimpleMoco(fullpathRex);
%%

h5path2_reg = movieRegister(h5path2_mc, h5path1_mc, 'shifts0', shifts0,...
    'shift_max', 1, 'angle_max', 5, 'corr_min', 0.3); % magic limit numbers from experience
% h5path1_reg = h5path1_reg;
%%

% h5path2_imp = movieImputeNaNS(h5path2_reg);
%%

movieMeanTraces([string(h5path1_mc), string(h5path2_reg)]);
movieMakeMask(h5path1_mc); movieMakeMask(h5path2_reg);
%%

if(~strcmp(h5path2_mc, h5path2_reg)), delete(h5path2_mc); end
if(~strcmp(fullpathGex, fullpathGin)), delete(fullpathGex); end
if(~strcmp(fullpathRex, fullpathRin)), delete(fullpathRex); end
if(~strcmp(fullpathGex, fullpathGconv)), delete(fullpathGin); end
if(~strcmp(fullpathRex, fullpathRconv)), delete(fullpathRin); end
%%

if(~strcmp(folder_output, folder_processing))
    displog("moving preprocessed data to: "+folder_output)
    if(~isdir(folder_output)), mkdir(folder_output); end
    allfiles = dir(folder_processing);
    cellfun(@(n) movefile(fullfile(folder_processing, n),  fullfile(folder_output, n)), ...
        {allfiles(3:end).name})
end
%%

currentfile = mfilename('fullpath') + ".m"; 
copyfile(currentfile, folder_output)