 
clear; 
close all;
warning on;
if(isempty(gcp('nocreate'))), parpool('Threads'); end 

diary(fullfile( ...
          "P:\GEVI_Wave\Logs", ...
          strcat(string(datetime('now','Format','yyyyMMddHHmmss')),'_',mfilename(),'.log')));
%%
% 
recording_name = "Anesthesia\m43\20230116\meas08\";
postfix_in1 = "cG_bin8_mc";
postfix_in2 = "cR_bin8_mc_reg";

mouse_state = "transition"; %"anesthesia"; % "awake"; %"transition";
skip_if_final_exists = false;

basefolder_preprocessed = "P:\GEVI_Wave\Preprocessed\";
basefolder_processing = "T:\GEVI_Wave\Preprocessed\";
basefolder_output = "N:\GEVI_Wave\Analysis\";    

crosstalk_matrix =  [[1, 0]; [0.07, 1]]; 
% 0.07 for ASAP3
% 0.095 for old ace recordings seems good - based on m14 visual v1
% 0.141 (?) for older ASAP2s with different filters
frame_range = [50, inf];
%%
% postfixed for the final files in the output location

postfix_out1 = "_unmixedTR_dFF";
postfix_out2 = "_dFF";
%%

folder_preprocessed = fullfile(basefolder_preprocessed, recording_name);
folder_processing = fullfile(basefolder_processing, recording_name);
folder_output = fullfile(basefolder_output, recording_name);
%%
% look for input files in the preprocessed location

file1 = dir(fullfile(folder_preprocessed, "/*" + postfix_in1 + ".h5"));
file2 = dir(fullfile(folder_preprocessed, "/*" + postfix_in2 + ".h5"));

if(isempty(file1)) 
    error("Unmixing:fileNotFound", "Green channel .h5 file not found")
elseif isempty(file2)
    error("Unmixing:fileNotFound", "Red channel .h5 file not found")
end

fullpathGpreproc = fullfile(file1.folder, file1.name);
fullpathRpreproc = fullfile(file2.folder, file2.name);

[~, ~, ext1, basefilename1, channel1, ~] = filenameParts(fullpathGpreproc);
fullpathGin = fullfile(folder_processing, file1.name);%basefilename1+channel1+"_preprocessed"+ext1);
[~, ~, ext2, basefilename2, channel2, ~] = filenameParts(fullpathRpreproc);
fullpathRin = fullfile(folder_processing, file2.name);%basefilename2+channel2+"_preprocessed"+ext2);
%%
% form the final file name and check if it already exists

finalfile_find = dir( fullfile(folder_output, strcat("cG" + postfix_out1 + ".h5")) );
if(~isempty(finalfile_find)) 
    finalfile = fullfile(finalfile_find.folder, finalfile_find.name);
    if(skip_if_final_exists)
        error("Final file exists, ending " + finalfile); 
    else
        warning("Final file exists and will be owerwritten " + finalfile); 
    end
end
%%
% move the initial files to the processing directory (fast rw location)

if(~strcmp(folder_preprocessed, folder_processing))
    disp("copying data to: "+folder_processing)
    if(~isfolder(folder_processing)) mkdir(folder_processing); end
    if(~isfile(fullpathGin)) copyfile(fullpathGpreproc, fullpathGin); end
    if(~isfile(fullpathRin)) copyfile(fullpathRpreproc, fullpathRin); end
    copyfile(fullfile(file2.folder, "alignment_images"), fullfile(folder_processing, "alignment_images"));
end
%%

% fullpaths_in_mean = movieMeanTraces([fullpathGin, fullpathRin], ...
%     'processingdir', folder_processing);
% fullpathGin = fullpaths_in_mean(1); fullpathRin = fullpaths_in_mean(2);
%%

fullpathGex = movieExtractFrames(fullpathGin, frame_range);
fullpathRex = movieExtractFrames(fullpathRin, frame_range);
%%

fullpathGor = movieRemoveOutlierFrames(fullpathGex, 'n_sd', 6, 'dt', 15);
fullpathRor = movieRemoveOutlierFrames(fullpathRex, 'n_sd', 6, 'dt', 15);
%%

% for movies where cameras weren't started synchroniously 
fullpathRdl = movieCompensateDelay(fullpathRor, fullpathGor, ...
    'min_lag_frames', 0.5, 'lag_estimator', 'phase' , 'f0', 30); % 'lag_estimator' , 'xcorr' % 'lag_estimator', 'phase' , 'f0', 30
fullpathGdl = fullpathGor;
% fullpathRdl = fullpathRor;
%%

delay = 0;
[fullpathGdx, fullpathRdx] = moviesDecrosstalk(fullpathGdl, fullpathRdl, crosstalk_matrix, ...
    'framedelay', delay, 'skip', true);
% fullpathGdx = fullpathGdl; fullpathRdx = fullpathRdl;
%%

fullpathGbl = movieExpBaselineCorrection(fullpathGdx, 'divide', false); 
fullpathRbl = movieExpBaselineCorrection(fullpathRdx, 'divide', false);
% fullpathGbl = movieRemoveMean(fullpathGdx, 'skip', true); 
% fullpathRbl = movieRemoveMean(fullpathRdx, 'skip', true);
%%

% Make sure that filter resonable, if not increase wp or decrease attn;
if mouse_state == "anesthesia",     f0_hp = 0.5; wp = 0.25; 
elseif mouse_state == "awake",      f0_hp = 1.5; wp = 0.5; 
elseif mouse_state == "transition", f0_hp = 0.5; wp = 0.25; 
else, error("unknown mouse_state = " + mouse_state); 
end

options_highpass = struct( 'attn', 1e5, 'rppl', 1e-2, 'skip', true);
options_highpass.filtersdir = "P:\GEVI_Wave\ConvolutionFilters\";    
options_highpass.exepath = "C:\Users\Vasily\repos\Voltage\TEMPO-processing\analysis\c_codes\compiled\hdf5_movie_convolution.exe";   

fullpathGhp = movieFilterHighpass(fullpathGbl, f0_hp, wp, options_highpass);
fullpathRhp = movieFilterHighpass(fullpathRbl, f0_hp, wp, options_highpass);

movieSavePreviewVideos(fullpathGhp, 'title', 'filtered', 'skip', options_highpass.skip)
movieSavePreviewVideos(fullpathRhp, 'title', 'filtered', 'skip', options_highpass.skip)
%%

if mouse_state == "anesthesia"
    options_hfilt = struct('dt', 2.5, 'fref_lims', [1.5, 15],  'max_delay', 30e-3);
elseif mouse_state == "awake" 
    options_hfilt = struct('dt', 1.0, 'fref_lims', [5.0, 20]);
elseif mouse_state == "transition"
    options_hfilt = struct('dt', 2.0, 'fref_lims', [1.5, 20], 'max_delay', 30e-3);
else
    error("unknown mouse_state = " + mouse_state);
end  

options_hfilt = mergeStructs({options_hfilt,  struct(...
    'flim_max', 20, 'max_amp_rel', 1.10, 'average_mm', 2, 'dt_slow', 20*options_hfilt.dt)});

% options_hfilt = rmfield(options_hfilt, 'dt_slow');
% fullpathGhemo = movieEstimateHemoGFilt(fullpathGhp, fullpathRhp, options_hfilt);

fullpathGhemo = movieEstimateHemoGFiltTR(fullpathGhp, fullpathRhp, options_hfilt);

moviesSavePreviewVideos([fullpathGhemo, fullpathRhp], ...
    'titles', ["reference filt", "reference ch"])
%%

fullpathGnh = movieRemoveHemoComponents(fullpathGhp, fullpathGhemo, ...
    'divide', false, 'postfix', "_nohemoTR");

moviesSavePreviewVideos([fullpathGnh, fullpathGhemo, fullpathGhp], ...
    'titles', ["unmixed", "reference filt", "voltage ch"])
%%

fullpathGnhDFF = movieDFF(fullpathGnh);
movieSavePreviewVideos(fullpathGnhDFF, 'title', 'G unmixed dF/F')

fullpathRfDFF = movieDFF(fullpathRhp);
movieSavePreviewVideos(fullpathRfDFF, 'title', 'R dF/F')
%%

fullpaths_mean = movieMeanTraces([string(fullpathGnhDFF), string(fullpathRfDFF)], 'space', true, 'f0', f0_hp);
    
options_spectrogram = struct('timewindow', 4, 'fw', 0.75, ...
    'processingdir', fullfile(folder_processing, 'processing', 'meanTraceSpectrogram'), ...
    'skip', false); %'correct1f', false, 
movieMeanTraceSpectrogram(fullpaths_mean(1), options_spectrogram);
movieMeanTraceSpectrogram(fullpaths_mean(2), options_spectrogram);
%%
% copy renamed final files to the output location

if(~strcmp(folder_processing, folder_output))
    if(~isfolder(folder_output)) mkdir(folder_output); end
    
    paths_out_new = [];
    for f_out = [string(fullpathGnhDFF), string(fullpathRfDFF)]
        %%
        [filedir, ~, fileext, ~, channel, postfix_out] = filenameParts(f_out);
        
        if(findstr(postfix_out, 'nohemo'))
            fullpath_new = fullfile(folder_output, channel + postfix_out1 + fileext);
        else
            fullpath_new = fullfile(folder_output, channel + postfix_out2 + fileext);
        end
        
        copyfile(f_out, fullpath_new); paths_out_new = [paths_out_new, fullpath_new];
        
        movieSavePreviewVideos(fullpath_new, 'title', channel + " dFF", 'skip', false);
    end

    fullpaths_mean_new = movieMeanTraces(paths_out_new, 'space', true, 'skip', false, 'f0', f0_hp);
    
    options_spectrogram.processingdir = ...
        fullfile(folder_output, 'processing', 'meanTraceSpectrogram');
    movieMeanTraceSpectrogram(fullpaths_mean_new(1), options_spectrogram);
    movieMeanTraceSpectrogram(fullpaths_mean_new(2), options_spectrogram);
end
%%
% delete all intermediate files

if(~strcmp(fullpathGin, fullpathGpreproc)) delete(fullpathGin); end
if(~strcmp(fullpathRin, fullpathRpreproc)) delete(fullpathRin); end

if(~strcmp(fullpathGex, fullpathGin)) delete(fullpathGex); end
if(~strcmp(fullpathRex, fullpathRin)) delete(fullpathRex); end

if(~strcmp(fullpathGor, fullpathGex)) delete(fullpathGor); end
if(~strcmp(fullpathRor, fullpathRex)) delete(fullpathRor); end

if(~strcmp(fullpathGdl, fullpathGor)) delete(fullpathGdl); end
if(~strcmp(fullpathRdl, fullpathRor)) delete(fullpathRdl); end

if(~strcmp(fullpathGdx, fullpathGdl)) delete(fullpathGdx); end
if(~strcmp(fullpathRdx, fullpathRdl)) delete(fullpathRdx); end

if(~strcmp(fullpathGbl, fullpathGdx)) delete(fullpathGbl); end
if(~strcmp(fullpathRbl, fullpathRdx)) delete(fullpathRbl); end

if(~strcmp(fullpathGdx, fullpathGhp)) delete(fullpathGhp); end
if(~strcmp(fullpathRdx, fullpathRhp)) delete(fullpathRhp); end

delete(fullpathGhemo); 
delete(fullpathGnh);
%%
% copy all remaining files to the preprocessed location

if(~strcmp(folder_preprocessed, folder_processing))
    disp("moving processed data to: "+folder_preprocessed)
    allfiles = dir(folder_processing);
    cellfun(@(n) movefile(fullfile(folder_processing, n),  folder_preprocessed), {allfiles(3:end).name})
end
%%
% save current .m file to the preprocessed location

currentfile = mfilename('fullpath') + ".m"; 
copyfile(currentfile, folder_preprocessed)

