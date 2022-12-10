% clear
% addpath("../../../../_matlab_libs/deconvolution/")
%%

% recording_name = "Whiskers\m20\20210621\meas00";
% postfix_in = "_bin8_reg_moco"; %_fr1-33000
% channels = ["G","R"];
% 
% basefolder_preprocessed = "P:\GEVI_Wave\Preprocessed\";
% basefolder_processing = "C:\GEVI_Wave\Preprocessed_temp\";
% basefolder_output = "N:\GEVI_Wave\Preprocessed\";
%%

folder_preprocessed = fullfile(basefolder_preprocessed, recording_name);
folder_processing = fullfile(basefolder_processing, recording_name);
folder_output = fullfile(basefolder_output, recording_name);
%%

file1 = dir(fullfile(folder_preprocessed, "/*" + "c" + channels(1) + postfix_in + ".h5"));
file2 = dir(fullfile(folder_preprocessed, "/*" + "c" + channels(2) + postfix_in + ".h5"));

if(isempty(file1)) 
    error("Unmixing:fileNotFound", "Green channel .h5 file not found")
elseif isempty(file2)
    error("Unmixing:fileNotFound", "Red channel .h5 file not found")
end

fullpathGpreproc = fullfile(file1.folder, file1.name);
fullpathRpreproc = fullfile(file2.folder, file2.name);

fullpathGin = fullfile(folder_processing, file1.name);
fullpathRin = fullfile(folder_processing, file2.name);
%%

[filedir, filename, fileext, basefilename, channel, ~] = filenameParts(fullpathGin);
final_file = fullfile(folder_preprocessed,...
    filename + "_fr20-Inf_decross_expBlC_highpassCPPf0=0.5valid_nohemoS_dFF.h5");

if(isfile(final_file)) error("File exists, ending " + final_file); end
%%

if(~strcmp(folder_preprocessed, folder_processing))
    if(~isfolder(folder_processing)) mkdir(folder_processing); end
    if(~isfile(fullpathGin)) copyfile(fullpathGpreproc, fullpathGin); end
    if(~isfile(fullpathRin)) copyfile(fullpathRpreproc, fullpathRin); end
%     copyfile(fullfile(file2.folder, "alignment_images"), fullfile(folder_processing, "alignment_images"));
end
%%
% if(~exist('fullpath_maskManual_forall','var') == 1 || ~isfile(fullpath_maskManual_forall))
%     fullpath_maskManual = fullfile(folder_processing, 'alignment_images', file1.name(1:(end-3))) + "_maskManual.bmp";
% %     fullpath_maskManual = fullpathGin{1}(1:(end-3)) + "_maskManual.bmp";
%     if(~isfile(fullpath_maskManual)) error("Mask file missing: " + fullpath_maskManual); end 
% else
%     fullpath_maskManual = fullpath_maskManual_forall;
% end
 
% fullpathGm = movieApplyMask(fullpathGin, fullpath_maskManual);
% fullpathRm = movieApplyMask(fullpathRin, fullpath_maskManual);
% 
fullpathGm = fullpathGin;
fullpathRm = fullpathRin;

%%
% 
% box_crop = mm.getCropBoxNaN(rw.h5readMovie(fullpathGm));
% fullpathGcs = movieCrop(fullpathGm, box_crop);
% fullpathRcs = movieCrop(fullpathRm, box_crop);

fullpathGcs = fullpathGm;
fullpathRcs = fullpathRm;
%%

frames_drop = 20;

fullpathGct = movieExtractFrames(fullpathGcs, [frames_drop, Inf]);
fullpathRct = movieExtractFrames(fullpathRcs, [frames_drop, Inf]);

% fullpathGct = fullpathGcs;
% fullpathRct = fullpathRcs;
%%

crosstalk_matrix =  [[1, 0]; [0.066, 1]]; %0.066 [[1, 0]; [0, 1]];
%i used to use 0.079 for newer ASAP3 but 0.65-0.68 seems to work much better; 
%0.1 for older ASAP2s with different filters 
%not sure this is correct, but it works for ASAP3 recordings
delay = 0;
[fullpathGd, fullpathRd] = moviesDecrosstalk(fullpathGct, fullpathRct, crosstalk_matrix, ...
    'framedelay', delay, 'skip', true);
% fullpathGd = fullpathGct; fullpathRd = fullpathRct;
%%

%fullpathGbl = movieRemoveMean(fullpathGd, 'skip', true);
%fullpathRbl = movieRemoveMean(fullpathRd, 'skip', true); 

fullpathGbl = movieExpBaselineCorrection(fullpathGd, 'skip', true); 
fullpathRbl = movieExpBaselineCorrection(fullpathRd, 'skip', true);
%%

% Make sure that filter resonable, if not increase wp or decrease attn;
% f0 ~0.7Hz+-0.3 for anesthesia, ~1.5 +- 0.5Hz for awake
f0 = 0.5; wp = 0.25; 
% f0 = 1.5; wp = 0.5; 
attn = 1e5;  rppl = 1e-2; 

options_highpass = struct( 'attn', attn, 'rppl', rppl,  'skip', true, ...
    'filtersdir', "P:\GEVI_Wave\ConvolutionFilters\", ...
    'exepath', "C:\Users\Vasily\repos\VoltageImagingAnalysis\analysis\c_codes\compiled\hdf5_movie_convolution.exe",...
    'num_cores', 22);   

fullpathGhp = movieFilterExternalHighpass(fullpathGbl, f0, wp, options_highpass);
movieSavePreviewVideos(fullpathGhp, 'title', 'filtered')

fullpathRhp = movieFilterExternalHighpass(fullpathRbl, f0, wp, options_highpass);
movieSavePreviewVideos(fullpathRhp, 'title', 'filtered')
%%

options_filt_anesthesia = ...
    struct('skip', true, 'dt', 4, 'naverage', 17, ...
           'max_delay', 10*1e-3, 'max_var', 2, ...
           'eps', 1e-5); %, 'df_reg', 5
% options_filt_visual = ...
%     struct('skip', true, 'dt', 2, 'naverage', 35, ...
%            'max_delay', 10*1e-3, 'max_var', 2.5, ...
%            'eps', 1e-5); %, 'df_reg', 5

%dt = 2s+ for asap3 cortex, dt = 1s for hippocampal data (noisy)
fullpathGhemo = ...
    movieEstimateHemoGFilt(fullpathGhp, fullpathRhp, options_filt_anesthesia);
%options.anesthesia = struct({})
%%

movieSavePreviewVideos(fullpathGhemo, 'title', 'hemo estimated')
%%

fullpathGnohemo = movieRemoveHemoComponents(fullpathGhp, fullpathGhemo, 'divide', false);
movieSavePreviewVideos(fullpathGnohemo, 'title', 'G unmixed')
%%

fullpathGnhDFF = movieDFF(fullpathGnohemo);
movieSavePreviewVideos(fullpathGnhDFF, 'title', 'G unmixed dF/F')

fullpathRfDFF = movieDFF(fullpathRhp);
movieSavePreviewVideos(fullpathRfDFF, 'title', 'R dF/F')
%%

% specs = rw.h5readMovieSpecs(fullpathGhp); h5save(fullpathGhp,  specs.fps, '/fps' );
% fullpathGumxf = unmixMoviesFast(char(fullpathGhp), char(fullpathRhp), [], 'MouseState','anesthesia'); %filename?
% specs.AddToHistory("unmixMoviesFast"); rw.h5saveMovieSpecs(fullpathGumxf, specs);
% movieSavePreviewVideos(fullpathGumxf, 'title', 'G unmxFast');

% movieDFF(fullpathGumxf);
%%

% delete(fullpathGumxf)
%%

fullpaths_mean = movieMeanTraces([string(fullpathGnhDFF), string(fullpathRfDFF)], 'space', true);
    
options_spectrogram = struct('f0', 2, 'timewindow', 4, 'df', 0.75, ...
    'processingdir', fullfile(folder_processing, "\processing\meanTraceSpectrogram\"), ...
    'correct1f', false, 'skip', false);
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

    fullpaths_mean_new = movieMeanTraces(paths_out_new, 'space', true, 'skip', false);
    
    options_spectrogram.processingdir = ...
        fullfile(folder_output, "\processing\meanTraceSpectrogram\");
    movieMeanTraceSpectrogram(fullpaths_mean_new(1), options_spectrogram);
    movieMeanTraceSpectrogram(fullpaths_mean_new(2), options_spectrogram);
end
%%


if(~strcmp(fullpathGin, fullpathGpreproc)) delete(fullpathGin); end
if(~strcmp(fullpathRin, fullpathRpreproc)) delete(fullpathRin); end

if(~strcmp(fullpathGm, fullpathGin)) delete(fullpathGm); end
if(~strcmp(fullpathRm, fullpathRin)) delete(fullpathRm); end

if(~strcmp(fullpathGcs, fullpathGin)) delete(fullpathGcs); end
if(~strcmp(fullpathRcs, fullpathRin)) delete(fullpathRcs); end

if(~strcmp(fullpathGct, fullpathGin)) delete(fullpathGct); end
if(~strcmp(fullpathRct, fullpathRin)) delete(fullpathRct); end

if(~strcmp(fullpathGd, fullpathGin)) delete(fullpathGd); end
if(~strcmp(fullpathRd, fullpathRin)) delete(fullpathRd); end

if(~strcmp(fullpathGbl, fullpathGin)) delete(fullpathGbl); end
if(~strcmp(fullpathRbl, fullpathRin)) delete(fullpathRbl); end

delete(fullpathGhp); delete(fullpathRhp);
delete(fullpathGhemo); delete(fullpathGnohemo);
%%

if(~strcmp(folder_preprocessed, folder_processing))
    allfiles = dir(folder_processing);
    cellfun(@(n) movefile(fullfile(folder_processing, n),  folder_preprocessed), {allfiles(3:end).name})
end
%%

currentfile = mfilename('fullpath') + ".m"; %"C:\Users\Vasily\repos\VoltageImagingAnalysis\usersPipelines\Vasily\manual_processing\pipelines\pipeline_preprocessing.m"
copyfile(currentfile, folder_preprocessed)

