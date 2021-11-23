% clear
addpath("../../../../_matlab_libs/deconvolution/")
%%
% 
basepath = "F:\GEVI_Wave\Preprocessed\Auditory\m41\20210717\meas00\";
postfix = "_bin8_reg_moco_cropMovie"; %
channels = ["G","R"];
%%

file1 = dir(fullfile(basepath, "/*" + "c" + channels(1) + postfix + ".h5"));
file2 = dir(fullfile(basepath, "/*" + "c" + channels(2) + postfix + ".h5"));


fullpathGin = fullfile(file1.folder, file1.name);
fullpathRin = fullfile(file2.folder, file2.name);
%%

fullpath_maskManual = fullpathGin(1:(end-3)) + "_maskManual.bmp";

fullpathGm = movieApplyMask(fullpathGin, fullpath_maskManual);
fullpathRm = movieApplyMask(fullpathRin, fullpath_maskManual);
%%
% [[1, 0]; [0.0725, 1]];
crosstalk_matrix =  [[1, 0]; [0.079, 1]]; %0.079 for newer ASAP3, 0.108? for older ASAP2s with different filters %not sure this is correct, but it works for ASAP3 recordings
delay = 0;
[fullpathGd, fullpathRd] = moviesDecrosstalk(fullpathGm, fullpathRm, crosstalk_matrix, ...
    'framedelay', delay, 'skip', true);
% fullpathGd = fullpathGin; fullpa thRd = fullpathRin;
%%

% fullpathGbl = movieRemoveMean(fullpathGd, 'skip', true);
% fullpathRbl = movieRemoveMean(fullpathRd, 'skip', true); 

fullpathGbl = movieExpBaselineCorrection(fullpathGd, 'skip', true); %movieRemoveMean(fullpathGd); %
fullpathRbl = movieExpBaselineCorrection(fullpathRd, 'skip', true); %movieRemoveMean(fullpathRd); %
%%

f0= 0.5; wp = 0.4; % Make sure that filter looks more or less like a delta-function, not like derivative; Something about filter design needs a fix
attn = 1e5;  rppl = 1e-2; 

[fullpathGhp, ~] =movieFilterExternalHighpass(...
    fullpathGbl, f0, wp,...
    'attn', attn, 'rppl', rppl, ...
    'filtersdir', "F:\ConvolutionFilters\", ...
    'outdir', basepath, 'skip', true, ...
    'exepath', "C:\Users\Vasily\repos\VoltageImagingAnalysis\analysis\c_codes\compiled\hdf5_movie_convolution.exe");


[fullpathRhp, ~] = movieFilterExternalHighpass(...
    fullpathRbl, f0, wp, ...
    'attn', attn, 'rppl', rppl, ...
    'filtersdir', "F:\ConvolutionFilters\", ...
    'outdir', basepath, 'skip', true, ...
    'exepath', "C:\Users\Vasily\repos\VoltageImagingAnalysis\analysis\c_codes\compiled\hdf5_movie_convolution.exe");

%%
 
fullpathGdFF = fullpathGhp; %movieDFF(fullpathGhp);
fullpathRdFF = fullpathRhp; %movieDFF(fullpathRhp);
%%

fullpathGhemo = ...
    movieEstimateHemoGFilt(fullpathGdFF, fullpathRdFF, 'dt', 2, 'eps', .1, 'average_first', true);%, 'reg_func', @(z,n) mean(z));
%%

fullpathGnohemo = movieRemoveHemoComponents(fullpathGdFF, fullpathGhemo, 'divide', true);
fullpathGnhDFF = movieDFF(fullpathGnohemo);
fullpathRnhDFF = movieDFF(fullpathRdFF);
%%
df = 0.2;

movieMultitaperExternal(fullpathGnohemo, 'df', df, 'outdir', fullfile(basepath, "/PSD/"), ...
    'exepath', "C:\Users\Vasily\repos\VoltageImagingAnalysis\analysis\c_codes\compiled\hdf5_movie_fft.exe",...
    'f0plot', f0, 'tol',  1e-4, 'num_cores', 16, 'skip', false);

movieMultitaperExternal(fullpathGnhDFF, 'df', df, 'outdir', fullfile(basepath, "/PSD/"), ...
    'exepath', "C:\Users\Vasily\repos\VoltageImagingAnalysis\analysis\c_codes\compiled\hdf5_movie_fft.exe",...
    'f0plot', f0, 'tol',  1e-4, 'num_cores', 16, 'skip', false);


movieMultitaperExternal(fullpathGhp, 'df', df, 'outdir', fullfile(basepath, "/PSD/"),...
    'exepath', "C:\Users\Vasily\repos\VoltageImagingAnalysis\analysis\c_codes\compiled\hdf5_movie_fft.exe", ...
    'f0plot', f0, 'tol',  1e-4, 'num_cores', 16, 'skip', true);

movieMultitaperExternal(fullpathRhp, 'df', df, 'outdir', fullfile(basepath, "/PSD/"),...
    'exepath', "C:\Users\Vasily\repos\VoltageImagingAnalysis\analysis\c_codes\compiled\hdf5_movie_fft.exe", ...
    'f0plot', f0, 'tol',  1e-4, 'num_cores', 16, 'skip', true);

%%

currentfile = mfilename('fullpath') + ".m"; %"C:\Users\Vasily\repos\VoltageImagingAnalysis\usersPipelines\Vasily\manual_processing\pipelines\pipeline_preprocessing.m"
copyfile(currentfile, basepath)

