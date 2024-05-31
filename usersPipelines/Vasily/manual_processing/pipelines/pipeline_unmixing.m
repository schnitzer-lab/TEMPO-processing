
% recording_name = "Visual\m40\20210824\meas00";
% postfix_in1 = "cG_bin8_mc";
% postfix_in2 = "cR_bin8_mc_reg";
% 
% mouse_state = "awake"; %"anesthesia"; % "awake"; %"transition";
% skip_if_final_exists = false;
% 
% basefolder_preprocessed = "P:\GEVI_Wave\Preprocessed\";
% basefolder_processing = "T:\GEVI_Wave\Preprocessed\";
% basefolder_output = "N:\GEVI_Wave\Analysis\";    
% 
% crosstalk_matrix =  [[1, 0]; [0.07, 1]]; 
% % 0.07 for ASAP3
% % 0.095 for old ace recordings seems good - based on m14 visual v1
% % 0.141 for older ASAP2s with different filters ??
% % not sure this is correct, but it works for ASAP3 recordings
% frame_range = [50, inf];
%%

folder_preprocessed = fullfile(basefolder_preprocessed, recording_name);
folder_processing = fullfile(basefolder_processing, recording_name);
folder_output = fullfile(basefolder_output, recording_name);
%%

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

[filedir, filename, fileext, basefilename, channel, ~] = filenameParts(fullpathGin);
final_file = fullfile(folder_preprocessed,...
    filename + "*_nohemoS_dFF.h5");
result = dir(final_file);
if(~isempty(result)) 
    if(skip_if_final_exists)
        error("Final file exists, ending " + fullfile(result.folder, result.name)); 
    else
        warning("Final file exists and will be owerwritten " + fullfile(result.folder, result.name)); 
    end
end
%%

if(~strcmp(folder_preprocessed, folder_processing))
    disp("copying data to: "+folder_processing)
    if(~isfolder(folder_processing)) mkdir(folder_processing); end
    if(~isfile(fullpathGin)) copyfile(fullpathGpreproc, fullpathGin); end
    if(~isfile(fullpathRin)) copyfile(fullpathRpreproc, fullpathRin); end
    copyfile(fullfile(file2.folder, "alignment_images"), fullfile(folder_processing, "alignment_images"));
end
%%

fullpathGex = movieExtractFrames(fullpathGin, frame_range);
fullpathRex = movieExtractFrames(fullpathRin, frame_range);
%%

fullpathGor = movieRemoveOutlierFrames(fullpathGex, 'n_sd', 6, 'dt', 15);
fullpathRor = movieRemoveOutlierFrames(fullpathRex, 'n_sd', 6, 'dt', 15);
%%

% for movies where cameras weren't started synchroniously 
% (i.e. left on internal trigger) - find delay throug mean traces xcorr (hemo frequency)
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
if mouse_state == "anesthesia"
    f0_hp = 0.5; wp = 0.25; 
elseif mouse_state == "awake"
   f0_hp = 1.5; wp = 0.5; 
elseif mouse_state == "transition"
   f0_hp = 1.0; wp = 0.5; 
else
    error('state must be "anesthesia" or "awake"');
end

attn = 1e5;  rppl = 1e-2; 

options_highpass = struct( 'attn', attn, 'rppl', rppl,  'skip', true, ...
    'filtersdir', "P:\GEVI_Wave\ConvolutionFilters\", ...
    'exepath', "C:\Users\Vasily\repos\Voltage\VoltageImagingAnalysis\analysis\c_codes\compiled\hdf5_movie_convolution.exe",...
    'num_cores', 22);   

fullpathGhp = movieFilterExternalHighpass(fullpathGbl, f0_hp, wp, options_highpass);
movieSavePreviewVideos(fullpathGhp, 'title', 'filtered')

fullpathRhp = movieFilterExternalHighpass(fullpathRbl, f0_hp, wp, options_highpass);
movieSavePreviewVideos(fullpathRhp, 'title', 'filtered')
%%


if mouse_state == "anesthesia"
    options_hfilt = ...
        struct('skip', true, 'dt', 2.5, 'average_mm', 2, ...
               'max_amp_rel', 1.1, 'fref_lims', [1.5, 15], 'flim_max', 20, ...
               'max_delay', 30e-3, 'eps', 1e-8);
elseif mouse_state == "awake"
    options_hfilt = ...
        struct('skip', true, 'dt', 1, 'average_mm', 2, ...
               'max_amp_rel', 1.1, 'fref_lims', [5, 20], 'flim_max', 20, ...
               'eps', 1e-8);
elseif mouse_state == "transition"
    options_hfilt = ...
        struct('skip', true, 'dt', 1.5, 'average_mm', 2, ...
               'max_amp_rel', 1.1, 'fref_lims', [2, 20], 'flim_max', 20, ...
               'eps', 1e-8);
else
    error('state must be "anesthesia" or "awake"');
end

% options_hfilt.fref = 3.6
fullpathGhemo = ...
    movieEstimateHemoGFilt(fullpathGhp, fullpathRhp, options_hfilt);

moviesSavePreviewVideos([fullpathGhemo, fullpathRhp], ...
    'titles', ["reference filt", "reference ch"])
%%

fullpathGnh = movieRemoveHemoComponents(fullpathGhp, fullpathGhemo, ...
    'divide', false);

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
    'processingdir', fullfile(folder_processing, "\processing\meanTraceSpectrogram\"), ...
    'skip', false); %'correct1f', false, 
movieMeanTraceSpectrogram(fullpaths_mean(1), options_spectrogram);
movieMeanTraceSpectrogram(fullpaths_mean(2), options_spectrogram);
%%

if(~strcmp(folder_processing, folder_output))
    if(~isfolder(folder_output)) mkdir(folder_output); end
    
    paths_out_new = [];
    for f_out = [string(fullpathGnhDFF), string(fullpathRfDFF)]
        %%
        [filedir, ~, fileext, ~, channel, postfix_out] = filenameParts(f_out);
        
        if(findstr(postfix_out, 'nohemo'))
            fullpath_new = fullfile(folder_output, channel + "_unmixed_dFF" + fileext);
        else
            fullpath_new = fullfile(folder_output, channel + "_dFF" + fileext);
        end
        
        copyfile(f_out, fullpath_new); paths_out_new = [paths_out_new, fullpath_new];
        
        movieSavePreviewVideos(fullpath_new, 'title', channel + " dFF", 'skip', false);
    end

    fullpaths_mean_new = movieMeanTraces(paths_out_new, 'space', true, 'skip', false, 'f0', f0_hp);
    
    options_spectrogram.processingdir = ...
        fullfile(folder_output, "\processing\meanTraceSpectrogram\");
    movieMeanTraceSpectrogram(fullpaths_mean_new(1), options_spectrogram);
    movieMeanTraceSpectrogram(fullpaths_mean_new(2), options_spectrogram);
end
%%

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

if(~strcmp(folder_preprocessed, folder_processing))
    disp("moving processed data to: "+folder_preprocessed)
    allfiles = dir(folder_processing);
    cellfun(@(n) movefile(fullfile(folder_processing, n),  folder_preprocessed), {allfiles(3:end).name})
end
%%

currentfile = mfilename('fullpath') + ".m"; 
copyfile(currentfile, folder_preprocessed)

