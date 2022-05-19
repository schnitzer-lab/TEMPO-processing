% clear
% addpath("../../../../_matlab_libs/deconvolution/")
%%

% basepath = "P:\GEVI_Wave\Preprocessed\Anesthesia\m56\20220125\meas00";
% postfix = "_bin8_reg_moco_cropMovie"; %_fr1-33000
% channels = ["G","R"];
%%

analysis_drive = "N:";
%%

file1 = dir(fullfile(basepath, "/*" + "c" + channels(1) + postfix + ".h5"));
file2 = dir(fullfile(basepath, "/*" + "c" + channels(2) + postfix + ".h5"));

fullpathGin = fullfile(file1.folder, file1.name);
fullpathRin = fullfile(file2.folder, file2.name);
%%

fullpath_maskManual = fullpathGin(1:(end-3)) + "_maskManual.bmp";
 
fullpathGm = movieApplyMask(fullpathGin, fullpath_maskManual);
fullpathRm = movieApplyMask(fullpathRin, fullpath_maskManual);

% fullpathGm = fullpathGin;
% fullpathRm = fullpathRin;
%%

% h5path1_crop = movieCrop(h5path1_mc, box);
%%

crosstalk_matrix =  [[1, 0]; [0.066, 1]]; %0.066 [[1, 0]; [0, 1]];
%i used to use 0.079 for newer ASAP3 but 0.65-0.68 seems to work much better; 
%0.1 for older ASAP2s with different filters 
%not sure this is correct, but it works for ASAP3 recordings
delay = 0;
[fullpathGd, fullpathRd] = moviesDecrosstalk(fullpathGm, fullpathRm, crosstalk_matrix, ...
    'framedelay', delay, 'skip', true);
% fullpathGd = fullpathGin; fullpathRd = fullpathRin;
%%

%fullpathGbl = movieRemoveMean(fullpathGd, 'skip', true);
%fullpathRbl = movieRemoveMean(fullpathRd, 'skip', true); 

fullpathGbl = movieExpBaselineCorrection(fullpathGd, 'skip', true); 
fullpathRbl = movieExpBaselineCorrection(fullpathRd, 'skip', true);

%%

f0= 0.5; wp = 0.25; % Make sure that filter looks more or less like a delta-function, not like derivative; Something about filter design needs a fix
attn = 1e5;  rppl = 1e-2; 

options_highpass = struct( 'attn', attn, 'rppl', rppl,  'skip', true, ...
    'filtersdir', "P:\GEVI_Wave\ConvolutionFilters\", ...
    'exepath', "C:\Users\Vasily\repos\VoltageImagingAnalysis\analysis\c_codes\compiled\hdf5_movie_convolution.exe");

fullpathGhp = movieFilterExternalHighpass(fullpathGbl, f0, wp, options_highpass);
movieSavePreviewVideos(fullpathGhp, 'title', 'filtered')

fullpathRhp = movieFilterExternalHighpass(fullpathRbl, f0, wp, options_highpass);
movieSavePreviewVideos(fullpathRhp, 'title', 'filtered')

%%

fullpathGhemo = movieEstimateHemoGFilt(fullpathGhp, fullpathRhp, ...
    'dt', 5, 'eps', .1, 'average_first', true, 'skip', true);%, 'reg_func', @(z,n) mean(z));
movieSavePreviewVideos(fullpathGhemo, 'title', 'hemo estimated')
%%

fullpathGnohemo = movieRemoveHemoComponents(fullpathGhp, fullpathGhemo, 'divide', true);
movieSavePreviewVideos(fullpathGnohemo, 'title', 'G unmixed')

fullpathGnhDFF = movieDFF(fullpathGnohemo);
movieSavePreviewVideos(fullpathGnhDFF, 'title', 'G unmixed dF/F')

fullpathRfDFF = movieDFF(fullpathRhp);
movieSavePreviewVideos(fullpathRfDFF, 'title', 'R dF/F')
%%

fullpaths_mean = movieMeanTraces([string(fullpathGnhDFF), string(fullpathRfDFF)], 'space', true);
    
options_spectrogram = struct('f0', 2, 'timewindow', 5, 'df', 0.75, ...
    'processingdir', fullfile(basepath, "\processing\meanTraceSpectrogram\"));
movieMeanTraceSpectrogram(fullpaths_mean(1), options_spectrogram);
movieMeanTraceSpectrogram(fullpaths_mean(2), options_spectrogram);
%%

for f_out = [string(fullpathGnhDFF), string(fullpathRfDFF)]
    
    [filedir, ~, fileext, ~, channel, ~] = filenameParts(f_out);
    filedir_new = fullfile(analysis_drive, extractAfter(filedir,2));
    if(~isfolder(filedir_new)) mkdir(filedir_new); end

    fullpath_new = fullfile(filedir_new, channel+"_unmixed_dFF" + fileext);
    
    if(~isfile(fullpath_new))
        disp("copying "+fullpath_new);
        copyfile(f_out, fullpath_new);
    end
end
%%

if(~strcmp(fullpathGin, fullpathGm))
    delete(fullpathGm);
end
if(~strcmp(fullpathRin, fullpathRm))
    delete(fullpathRm);
end
delete(fullpathGd);
delete(fullpathRd);

delete(fullpathGhp);
delete(fullpathRhp);

delete(fullpathGnohemo);
%%
df = 0.2;

% movieMultitaperExternal(fullpathGnohemo, 'df', df, 'outdir', fullfile(basepath, "/PSD/"), ...
%     'exepath', "C:\Users\Vasily\repos\VoltageImagingAnalysis\analysis\c_codes\compiled\hdf5_movie_fft.exe",...
%     'f0plot', f0, 'tol',  1e-4, 'num_cores', 16, 'skip', true);
% 
% movieMultitaperExternal(fullpathGdFF, 'df', df, 'outdir', fullfile(basepath, "/PSD/"), ...
%     'exepath', "C:\Users\Vasily\repos\VoltageImagingAnalysis\analysis\c_codes\compiled\hdf5_movie_fft.exe",...
%     'f0plot', f0, 'tol',  1e-4, 'num_cores', 16, 'skip', true);
% movieMultitaperExternal(fullpathRdFF, 'df', df, 'outdir', fullfile(basepath, "/PSD/"), ...
%     'exepath', "C:\Users\Vasily\repos\VoltageImagingAnalysis\analysis\c_codes\compiled\hdf5_movie_fft.exe",...
%     'f0plot', f0, 'tol',  1e-4, 'num_cores', 16, 'skip', true);
% movieMultitaperExternal(fullpathRfDFF, 'df', df, 'outdir', fullfile(basepath, "/PSD/"), ...
%     'exepath', "C:\Users\Vasily\repos\VoltageImagingAnalysis\analysis\c_codes\compiled\hdf5_movie_fft.exe",...
%     'f0plot', f0, 'tol',  1e-4, 'num_cores', 16, 'skip', true);
% 
% movieMultitaperExternal(fullpathGnhDFF, 'df', df, 'outdir', fullfile(basepath, "/PSD/"), ...
%     'exepath', "C:\Users\Vasily\repos\VoltageImagingAnalysis\analysis\c_codes\compiled\hdf5_movie_fft.exe",...
%     'f0plot', f0, 'tol',  1e-4, 'num_cores', 16, 'skip', true);

% 
% movieMultitaperExternal(fullpathGhp, 'df', df, 'outdir', fullfile(basepath, "/PSD/"),...
%     'exepath', "C:\Users\Vasily\repos\VoltageImagingAnalysis\analysis\c_codes\compiled\hdf5_movie_fft.exe", ...
%     'f0plot', f0, 'tol',  1e-4, 'num_cores', 16, 'skip', true);
% 
% movieMultitaperExternal(fullpathRhp, 'df', df, 'outdir', fullfile(basepath, "/PSD/"),...
%     'exepath', "C:\Users\Vasily\repos\VoltageImagingAnalysis\analysis\c_codes\compiled\hdf5_movie_fft.exe", ...
%     'f0plot', f0, 'tol',  1e-4, 'num_cores', 16, 'skip', true);

%%

currentfile = mfilename('fullpath') + ".m"; %"C:\Users\Vasily\repos\VoltageImagingAnalysis\usersPipelines\Vasily\manual_processing\pipelines\pipeline_preprocessing.m"
copyfile(currentfile, basepath)

