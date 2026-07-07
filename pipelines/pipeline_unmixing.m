% %%
% 
% clear; 
% close all;
% warning on;
% if(isempty(gcp('nocreate'))), parpool('Threads'); end 
% 
% diary(fullfile( ...
%           "N:\GEVI_Wave\Logs", ...
%           strcat(string(datetime('now','Format','yyyyMMddHHmmss')),'_',mfilename(),'.log')));
% %%
% 
% recording_name = "Visual\m48\20210824\meas00"; 
% postfix_in1 = "cG_bin8*_mc";
% postfix_in2 = "cR_bin8*_mc_reg";
% 
% skip_if_final_exists = false;
% 
% mouse_state = "transition"; %"anesthesia"; % "awake"; %"transition";
% unmix_time_resolved = false;
% 
% basefolder_preprocessed = "F:\GEVI_Wave\Preprocessed\";
% basefolder_processing = "T:\GEVI_Wave\Preprocessed\";
% 
% crosstalk_matrix =  [[1, 0]; [0.072, 1]]; 
% % 0.072 for ASAP3 / ASAP5
% % 0.165 for ASAP7y
% % 0.095 for old ace recordings seems good - based on m14 visual v1
% % 0.141 (?) for older ASAP2s with different filters
%%

% postfixes for the final files in the output location
if(unmix_time_resolved), postfix_out1 = "_nohemoTRS_dFF"; 
else, postfix_out1 = "_nohemoS_dFF"; end %"_decross" + string(crosstalk_matrix(2))+"*
% postfix_out2 = "_dFF";
%%

folder_preprocessed = fullfile(basefolder_preprocessed, recording_name);
folder_processing = fullfile(basefolder_processing, recording_name);
%%
% look for input files in the preprocessed location

file1 = dir(fullfile(folder_preprocessed, "/*" + postfix_in1 + ".h5"));
file2 = dir(fullfile(folder_preprocessed, "/*" + postfix_in2 + ".h5"));

if(isempty(file1) || isempty(file2)) 
    error("Unmixing:fileNotFound", "input .h5 file not found")
elseif (length(file1) > 1 || length(file2) > 1)
    error("Unmixing:tooManyFiles", "too many input .h5 files found")
end

fullpathGpreproc = fullfile(file1.folder, file1.name);
fullpathRpreproc = fullfile(file2.folder, file2.name);

fullpathGin = fullfile(folder_processing, file1.name);
fullpathRin = fullfile(folder_processing, file2.name);
%%
% form the final file name and check if it already exists

finalfile_find = dir( fullfile(folder_preprocessed, strcat("*cG*" + postfix_out1 + ".h5")) );
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
    displog("copying data to: "+folder_processing)
    if(~isfolder(folder_processing)), mkdir(folder_processing); end
    if(~isfile(fullpathGin)), copyfile(fullpathGpreproc, fullpathGin); end
    if(~isfile(fullpathRin)), copyfile(fullpathRpreproc, fullpathRin); end
    copyfile(fullfile(file2.folder, "alignment_images"), fullfile(folder_processing, "alignment_images"));
end
%%

% to process individual traces

% movieCopyReference(fullpathGin, []);
% movieCopyReference(fullpathRin, []);
% fullpathGin = movieExtractRegionTrace(fullpathGin, 'V1');
% fullpathRin = movieExtractRegionTrace(fullpathRin, 'V1');

% fullpaths_in_mean = movieMeanTraces([fullpathGin, fullpathRin], ...
%     'processingdir', folder_processing);
% fullpathGin = fullpaths_in_mean(1); 
% fullpathRin = fullpaths_in_mean(2);
%%

fullpathGor = movieRemoveOutlierFrames(fullpathGin, 'n_sd', 20, 'dt', 20);
fullpathRor = movieRemoveOutlierFrames(fullpathRin, 'n_sd', 20, 'dt', 20);
% fullpathGor = fullpathGin;
% fullpathRor = fullpathRin;

%%

% for movies where cameras weren't started synchroniously 
fullpathGdl = fullpathGor;
fullpathRdl = movieCompensateDelay(fullpathRor, fullpathGor, ...
    'lag_estimator', 'phase', 'f0', 30,...
    'min_lag_frames', 0.75, 'max_lag_frames', 100); 
%%
    
[fullpathGdx, fullpathRdx] = moviesDecrosstalk(fullpathGdl, fullpathRdl, ...
    crosstalk_matrix, 'skip', true); %, 'postfix_new', "_decross"+num2str(crosstalk_matrix(2,1))
%%

fullpathGbl = movieExpBaselineCorrection(fullpathGdx, 'divide', false); 
fullpathRbl = movieExpBaselineCorrection(fullpathRdx, 'divide', false);
% fullpathGbl = movieRemoveMean(fullpathGdx, 'skip', true); 
% fullpathRbl = movieRemoveMean(fullpathRdx, 'skip', true);
%%

if mouse_state == "anesthesia",     f0_hp = 0.25; wp = 0.2; 
elseif mouse_state == "iso",        f0_hp = 0.15; wp = 0.075; 
elseif mouse_state == "awake",      f0_hp = 1.5; wp = 0.5; 
elseif mouse_state == "transition", f0_hp = 0.5; wp = 0.25; 
else, error("unknown mouse_state = " + mouse_state); 
end

options_highpass = struct( 'attn', 1e4, 'rppl', 1e-1, 'skip', true);
options_highpass.filtersdir = "..\analysis\convolution_filters\";    
options_highpass.exepath = "..\analysis\c_codes\compiled\hdf5_movie_convolution.exe";    % to use compiled executable. 3-4 times faster

% Make sure that filter resonable, if not increase wp or decrease attn;
fullpathGhp = movieFilterHighpass(fullpathGbl, f0_hp, wp, options_highpass);
fullpathRhp = movieFilterHighpass(fullpathRbl, f0_hp, wp, options_highpass);

movieSavePreviewVideos(fullpathGhp, 'title', 'filtered', 'skip', options_highpass.skip);
movieSavePreviewVideos(fullpathRhp, 'title', 'filtered', 'skip', options_highpass.skip);
%%

fullpathshp_mean = movieMeanTraces(...
    [string(fullpathGhp), string(fullpathRhp)], 'space', true);
    
options_spectrogram = struct('timewindow', 4, 'fw', 0.75, ...
    'processingdir', fullfile(folder_processing, 'processing', 'meanTraceSpectrogram')); %'correct1f', false, 
movieMeanTraceSpectrogram(fullpathshp_mean(2), options_spectrogram);
movieMeanTraceSpectrogram(fullpathshp_mean(1), options_spectrogram);
%%

if mouse_state == "awake" 
    options_hfilt = struct('dt', 1.5, 'fref_lims', [5.0,20], 'max_delay', 20*1e-3);
elseif mouse_state == "anesthesia"
    options_hfilt = struct('dt', 2.5, 'fref_lims', [1.5,15], 'max_delay', 30*1e-3);
elseif mouse_state == "transition"
    options_hfilt = struct('dt', 2.0, 'fref_lims', [1.5,20], 'max_delay', 30*1e-3);
elseif mouse_state == "iso"
    options_hfilt = struct('dt', 8.0, 'fref_lims', [1.5,15], 'max_delay', 20*1e-3);
else
    error("unknown mouse_state = " + mouse_state);
end  

options_hfilt = mergeStructs({options_hfilt,  ...
    struct('average_mm', 1, 'niter', 3, ...
           'max_amp_rel', 1.1, 'flim_max', 20)});

% options_hfilt.fref = 7; % to manually specify the ref (heartbeat) frequency

if(unmix_time_resolved)
    options_hfilt.dt_slow = 20*options_hfilt.dt; 
    fullpathGhemo = movieEstimateHemoGFiltTR(fullpathGhp, fullpathRhp, options_hfilt);
else
    options_hfilt.npixatonce = 5e3; % to prevent ram overflow
    fullpathGhemo = movieEstimateHemoGFilt(fullpathGhp, fullpathRhp, options_hfilt);
end

moviesSavePreviewVideos([fullpathGhemo, fullpathRhp], ...
    'titles', ["reference filt", "reference ch"]);
%%

postfix_nh = "_nohemo"; if(unmix_time_resolved), postfix_nh = "_nohemoTR"; end
fullpathGnh = movieRemoveHemoComponents(fullpathGhp, fullpathGhemo, ...
    'divide', false, 'postfix', postfix_nh);

moviesSavePreviewVideos([fullpathGnh, fullpathGhemo, fullpathGhp], ...
    'titles', ["unmixed", "reference filt", "voltage ch"]);

movieSaveSingleFrame(fullpathGnh, ...  
    'frametype', 'std', 'outdir', fullfile(folder_processing, "alignment_images"));
%%

fullpathRDFF = movieDFF(fullpathRhp);
fullpathRDFF_videos = movieSavePreviewVideos(fullpathRDFF, 'title', 'R dF/F');

fullpathGnhDFF = movieDFF(fullpathGnh);
fullpathGnhDFF_videos = movieSavePreviewVideos(fullpathGnhDFF, 'title', 'G unmixed dF/F');
%%

fullpathsDFF_mean = movieMeanTraces(...
    [string(fullpathGnhDFF), string(fullpathRDFF)], 'space', true);
    
options_spectrogram = struct('timewindow', 4, 'fw', 0.75, ...
    'processingdir', fullfile(folder_processing, 'processing', 'meanTraceSpectrogram')); %'correct1f', false, 
fullpathRDFF_spec = movieMeanTraceSpectrogram(fullpathsDFF_mean(2), options_spectrogram);
fullpathGnhDFF_spec = movieMeanTraceSpectrogram(fullpathsDFF_mean(1), options_spectrogram);
%% delete all intermediate files

if(~strcmp(fullpathGin, fullpathGpreproc)), delete(fullpathGin); end
if(~strcmp(fullpathRin, fullpathRpreproc)), delete(fullpathRin); end

if(~strcmp(fullpathGor, fullpathGin)), delete(fullpathGor); end
if(~strcmp(fullpathRor, fullpathRin)), delete(fullpathRor); end

if(~strcmp(fullpathGdl, fullpathGor)), delete(fullpathGdl); end
if(~strcmp(fullpathRdl, fullpathRor)), delete(fullpathRdl); end

if(~strcmp(fullpathGdx, fullpathGdl)), delete(fullpathGdx); end
if(~strcmp(fullpathRdx, fullpathRdl)), delete(fullpathRdx); end

if(~strcmp(fullpathGbl, fullpathGdx)), delete(fullpathGbl); end
if(~strcmp(fullpathRbl, fullpathRdx)), delete(fullpathRbl); end

if(~strcmp(fullpathGbl, fullpathGhp)), delete(fullpathGhp); end
if(~strcmp(fullpathRbl, fullpathRhp)), delete(fullpathRhp); end

delete(fullpathGhemo); 
delete(fullpathGnh);
%% copy all remaining files to the preprocessed location

if(~strcmp(folder_preprocessed, folder_processing))
    displog("moving processed data to: "+folder_preprocessed)
    allfiles = dir(folder_processing);
    cellfun(@(n) movefile(fullfile(folder_processing, n),  folder_preprocessed), {allfiles(3:end).name})
end
%% save current .m file to the preprocessed location

currentfile = mfilename('fullpath') + ".m"; 
copyfile(currentfile, folder_preprocessed)

