% clear
% addpath("../../../../_matlab_libs/deconvolution/")
%%

% basepath = "N:\GEVI_Wave_Monique\Preprocessed\Anesthesia\mAstr5299uk\20210919\meas01\";
% postfix = "_cr_mc_down8s_moco_cropMovie"; %_fr1-33000
% channels = ["G","R"];
%%

file1 = dir(fullfile(basepath, "/*" + "c" + channels(1) + postfix + ".h5"));
file2 = dir(fullfile(basepath, "/*" + "c" + channels(2) + postfix + ".h5"));

fullpathGin = fullfile(file1.folder, file1.name);
fullpathRin = fullfile(file2.folder, file2.name);
%%

% fullpath_maskManual = fullpathGin(1:(end-3)) + "_maskManual.bmp";
% 
% fullpathGm = movieApplyMask(fullpathGin, fullpath_maskManual);
% fullpathRm = movieApplyMask(fullpathRin, fullpath_maskManual);

fullpathGm = fullpathGin;
fullpathRm = fullpathRin;
%%
% [[1, 0]; [0.0725, 1]];
% crosstalk_matrix =  [[1, 0]; [0, 1]];
crosstalk_matrix =  [[1, 0]; [0.066, 1]]; 
%i used to use 0.079 for newer ASAP3 but 0.65-0.68 seems to work much better; 
%0.1 for older ASAP2s with different filters 
%not sure this is correct, but it works for ASAP3 recordings
delay = 0;
[fullpathGd, fullpathRd] = moviesDecrosstalk(fullpathGm, fullpathRm, crosstalk_matrix, ...
    'framedelay', delay, 'skip', true);
% fullpathGd = fullpathGin; fullpathRd = fullpathRin;
%%

fullpathGbl = movieRemoveMean(fullpathGd, 'skip', true);
fullpathRbl = movieRemoveMean(fullpathRd, 'skip', true); 

% fullpathGbl = movieExpBaselineCorrection(fullpathGd, 'skip', true); %movieRemoveMean(fullpathGd); %
% fullpathRbl = movieExpBaselineCorrection(fullpathRd, 'skip', true); %movieRemoveMean(fullpathRd); %

%%

f0= 0.5; wp = 0.4; % Make sure that filter looks more or less like a delta-function, not like derivative; Something about filter design needs a fix
attn = 1e5;  rppl = 1e-2; 

[fullpathGhp, ~] =movieFilterExternalHighpass(...
    fullpathGbl, f0, wp,...
    'attn', attn, 'rppl', rppl, ...
    'filtersdir', "P:\GEVI_Wave\ConvolutionFilters\", ...
    'outdir', basepath, 'skip', true, ...
    'exepath', "C:\Users\Vasily\repos\VoltageImagingAnalysis\analysis\c_codes\compiled\hdf5_movie_convolution.exe");

[fullpathRhp, ~] = movieFilterExternalHighpass(...
    fullpathRbl, f0, wp, ...
    'attn', attn, 'rppl', rppl, ...
    'filtersdir', "P:\GEVI_Wave\ConvolutionFilters\", ...
    'outdir', basepath, 'skip', true, ...
    'exepath', "C:\Users\Vasily\repos\VoltageImagingAnalysis\analysis\c_codes\compiled\hdf5_movie_convolution.exe");

%%
 
% fullpathGdFF = movieDFF(fullpathGhp); %fullpathGhp; %
% fullpathRdFF = movieDFF(fullpathRhp); %fullpathRhp;
%%

fullpathGhemo = ...
    movieEstimateHemoGFilt(fullpathGhp, fullpathRhp, 'dt', 2, 'eps', 0.1, 'average_first', true,...
        'skip', true);%, 'reg_func', @(z,n) mean(z));
%%

fullpathGnohemo = movieRemoveHemoComponents(fullpathGhp, fullpathGhemo, 'divide', true);
% fullpathGnhDFF = movieDFF(fullpathGnohemo);
% fullpathRfDFF = movieDFF(fullpathGhemo);
%%
%%

if(~strcmp(fullpathGin, fullpathGm))
    delete(fullpathGm);
end
if(~strcmp(fullpathRin, fullpathRm))
    delete(fullpathRm);
end
delete(fullpathGd);
delete(fullpathRd);

% delete(fullpathGhp);
% delete(fullpathRhp);

% delete(fullpathGnohemo);
%%

% movieDownsample(fullpathGnhDFF, 1, 4)
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

