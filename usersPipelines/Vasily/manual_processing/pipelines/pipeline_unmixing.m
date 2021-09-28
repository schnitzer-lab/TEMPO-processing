% clear
addpath("../../../../_matlab_libs/deconvolution/")
%%
% 
basepath = "F:\GEVI_Wave\Preprocessed\Anesthesia\m11\20201013\meas07\";
basefilename = "/m11_d201013_s07_--fps120-c";
postfix = "_bin8_reg_moco_cropMovie_masked"; %_masked
channels = ["G","R"];
%%

fullpathGin = fullfile(basepath, [basefilename + channels(1) + postfix + ".h5"]);
fullpathRin = fullfile(basepath, [basefilename + channels(2) + postfix + ".h5"]);
%%
% [[1, 0]; [0.0725, 1]];
crosstalk_matrix =  [[1, 0]; [0.079, 1]]; %not sure this is correct, but it works for ASAP3 recordings
[fullpathGd, fullpathRd] = moviesDecrosstalk(fullpathGin, fullpathRin, crosstalk_matrix);
% fullpathGd = fullpathGin; fullpathRd = fullpathRin;
%%

f0= 0.5; wp = 0.4; % Make sure that filter looks more or less like a delta-function, not like derivative; Something about filter design needs a fix
attn = 1e5;  rppl = 1e-2; 

[fullpathGhp, ~] =movieFilterExternalHighpass(...
    fullpathGd, f0, wp,...
    'attn', attn, 'rppl', rppl, ...
    'filtersdir', "F:\ConvolutionFilters\", ...
    'outdir', basepath, 'skip', true, ...
    'exepath', "C:\Users\Vasily\repos\VoltageImagingAnalysis\analysis\c_codes\compiled\hdf5_movie_convolution.exe");

[fullpathRhp, ~] = movieFilterExternalHighpass(...
    fullpathRd, f0, wp, ...
    'attn', attn, 'rppl', rppl, ...
    'filtersdir', "F:\ConvolutionFilters\", ...
    'outdir', basepath, 'skip', true, ...
    'exepath', "C:\Users\Vasily\repos\VoltageImagingAnalysis\analysis\c_codes\compiled\hdf5_movie_convolution.exe");

%%
 
fullpathGhemo = ...
    movieEstimateHemoGFilt(fullpathGhp, fullpathRhp, 'dt', 2, 'eps', .1, 'average_first', true);%, 'reg_func', @(z,n) mean(z));
%%

fullpathGnohemo = movieRemoveHemoComponents(fullpathGhp, fullpathGhemo);
%%
df = 0.2;

movieMultitaperExternal(fullpathGnohemo, 'df', df, 'outdir', fullfile(basepath, "/PSD/"), ...
    'exepath', "C:\Users\Vasily\repos\VoltageImagingAnalysis\analysis\c_codes\compiled\hdf5_movie_fft.exe",...
    'f0plot', f0, 'tol',  1e-4, 'num_cores', 16, 'skip', false);


movieMultitaperExternal(fullpathGhp, 'df', df, 'outdir', fullfile(basepath, "/PSD/"),...
    'exepath', "C:\Users\Vasily\repos\VoltageImagingAnalysis\analysis\c_codes\compiled\hdf5_movie_fft.exe", ...
    'f0plot', f0, 'tol',  1e-4, 'num_cores', 16, 'skip', true);

movieMultitaperExternal(fullpathRhp, 'df', df, 'outdir', fullfile(basepath, "/PSD/"),...
    'exepath', "C:\Users\Vasily\repos\VoltageImagingAnalysis\analysis\c_codes\compiled\hdf5_movie_fft.exe", ...
    'f0plot', f0, 'tol',  1e-4, 'num_cores', 16, 'skip', true);

%%



