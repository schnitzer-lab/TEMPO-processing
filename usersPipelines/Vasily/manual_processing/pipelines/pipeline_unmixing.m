% clear
% addpath("../../../../_matlab_libs/deconvolution/")
%%

% recording_name = "Visual\m41\20210824\meas00";
% postfix_in = "_bin8_reg_moco"; %_fr1-33000
% channels = ["G","R"];
% 
% basefolder_preprocessed = "P:\GEVI_Wave\Preprocessed\";
% basefolder_processing = "C:\GEVI_Wave\Preprocessed\";
% basefolder_output = "N:\GEVI_Wave\Preprocessed\";
%%

fullfolder_preprocessed = fullfile(basefolder_preprocessed, recording_name);
fullfolder_processing = fullfile(basefolder_processing, recording_name);
fullfolder_output = fullfile(basefolder_output, recording_name);
%%

file1 = dir(fullfile(fullfolder_preprocessed, "/*" + "c" + channels(1) + postfix_in + ".h5"));
file2 = dir(fullfile(fullfolder_preprocessed, "/*" + "c" + channels(2) + postfix_in + ".h5"));

if(isempty(file1)) 
    error("Unmixing:fileNotFound", "Green channel .h5 file not found")
elseif isempty(file2)
    error("Unmixing:fileNotFound", "Red channel .h5 file not found")
end

fullpathGpreproc = fullfile(file1.folder, file1.name);
fullpathRpreproc = fullfile(file2.folder, file2.name);

fullpathGin = fullfile(fullfolder_processing, file1.name);
fullpathRin = fullfile(fullfolder_processing, file2.name);
%%

[filedir, filename, fileext, basefilename, channel, ~] = filenameParts(fullpathGin);
final_file = fullfile(fullfolder_preprocessed,...
    filename + "_masked_crop_fr20-Inf_decross_expBlC_highpassCPPf0=1wp=0.3valid_nohemoD_dFF.h5");

if(isfile(final_file)) error("File exists, ending " + final_file); end
%%

if(~strcmp(fullfolder_preprocessed, fullfolder_processing))
    if(~isfolder(fullfolder_processing)) mkdir(fullfolder_processing); end
    copyfile(fullpathGpreproc, fullpathGin);
    copyfile(fullpathRpreproc, fullpathRin);
    copyfile(fullfile(file2.folder, "*.bmp"), fullfolder_processing);
end
%%

if(~exist('fullpath_maskManual_forall','var') == 1 || ~isfile(fullpath_maskManual_forall))
    fullpath_maskManual = fullpathGin{1}(1:(end-3)) + "_maskManual.bmp";
    if(~isfile(fullpath_maskManual)) error("Mask file missing: " + fullpath_maskManual); end 
else
    fullpath_maskManual = fullpath_maskManual_forall;
end
 
fullpathGm = movieApplyMask(fullpathGin, fullpath_maskManual);
fullpathRm = movieApplyMask(fullpathRin, fullpath_maskManual);

% fullpathGm = fullpathGin;
% fullpathRm = fullpathRin;
%%

% box_crop = mm.getCropBoxNaN(rw.h5readMovie(fullpathGm));
% fullpathGcs = movieCrop(fullpathGm, box_crop);
% fullpathRcs = movieCrop(fullpathRm, box_crop);

fullpathGcs = fullpathGm;
fullpathRcs = fullpathRm;
%%

frames_drop = 20;

fullpathGct = movieExtractFrames(fullpathGcs, [frames_drop, Inf]);
fullpathRct = movieExtractFrames(fullpathRcs, [frames_drop, Inf]);
%%

crosstalk_matrix =  [[1, 0]; [0.066, 1]]; %0.066 [[1, 0]; [0, 1]];
%i used to use 0.079 for newer ASAP3 but 0.65-0.68 seems to work much better; 
%0.1 for older ASAP2s with different filters 
%not sure this is correct, but it works for ASAP3 recordings
delay = 0;
[fullpathGd, fullpathRd] = moviesDecrosstalk(fullpathGct, fullpathRct, crosstalk_matrix, ...
    'framedelay', delay, 'skip', true);
% fullpathGd = fullpathGm; fullpathRd = fullpathRm;
%%

%fullpathGbl = movieRemoveMean(fullpathGd, 'skip', true);
%fullpathRbl = movieRemoveMean(fullpathRd, 'skip', true); 

fullpathGbl = movieExpBaselineCorrection(fullpathGd, 'skip', true); 
fullpathRbl = movieExpBaselineCorrection(fullpathRd, 'skip', true);
%%

% Make sure that filter resonable, if not increase wp or decrease attn;
% f0 ~0.6Hz for anesthesia, ~1Hz for awake
f0 = 1; wp = 0.3; 
attn = 1e5;  rppl = 1e-2; 

options_highpass = struct( 'attn', attn, 'rppl', rppl,  'skip', true, ...
    'filtersdir', "P:\GEVI_Wave\ConvolutionFilters\", ...
    'exepath', "C:\Users\Vasily\repos\VoltageImagingAnalysis\analysis\c_codes\compiled\hdf5_movie_convolution.exe", ...
    'num_cores', 16);

fullpathGhp = movieFilterExternalHighpass(fullpathGbl, f0, wp, options_highpass);
movieSavePreviewVideos(fullpathGhp, 'title', 'filtered')

fullpathRhp = movieFilterExternalHighpass(fullpathRbl, f0, wp, options_highpass);
movieSavePreviewVideos(fullpathRhp, 'title', 'filtered')
%%

%dt = 2s+ for asap3 cortex, dt = 1s for hippocampal data (noisy)
fullpathGhemo = movieEstimateHemoGFilt(fullpathGhp, fullpathRhp, ...
    'dt', 1, 'eps', 0.1, 'max_phase', pi, 'max_delay', Inf,...
    'average_first', true, 'use_separation', true, 'skip', true);
%options.anesthesia = struct({})

movieSavePreviewVideos(fullpathGhemo, 'title', 'hemo estimated')


fullpathGnohemo = movieRemoveHemoComponents(fullpathGhp, fullpathGhemo, 'divide', true);
movieSavePreviewVideos(fullpathGnohemo, 'title', 'G unmixed')
%%

fullpathGnhDFF = movieDFF(fullpathGnohemo);
movieSavePreviewVideos(fullpathGnhDFF, 'title', 'G unmixed dF/F')

fullpathRfDFF = movieDFF(fullpathRhp);
movieSavePreviewVideos(fullpathRfDFF, 'title', 'R dF/F')
%%

% specs = rw.h5readMovieSpecs(fullpathGhp); h5save(fullpathGhp,  specs.fps, '/fps' );
% fullpathGumxf = unmixMoviesFast(char(fullpathGhp), char(fullpathRhp)); %filename?
% specs.AddToHistory("unmixMoviesFast"); rw.h5saveMovieSpecs(fullpathGumxf, specs);
% 
% movieDFF(fullpathGumxf);
%%

fullpaths_mean = movieMeanTraces([string(fullpathGnhDFF), string(fullpathRfDFF)], 'space', true);
    
options_spectrogram = struct('f0', 2, 'timewindow', 4, 'df', 0.75, ...
    'processingdir', fullfile(fullfolder_preprocessed, "\processing\meanTraceSpectrogram\"), ...
    'correct1f', false);
movieMeanTraceSpectrogram(fullpaths_mean(1), options_spectrogram);
movieMeanTraceSpectrogram(fullpaths_mean(2), options_spectrogram);
%%

if(~strcmp(fullfolder_processing, fullfolder_output))
    if(~isfolder(fullfolder_output)) mkdir(fullfolder_output); end
    
    paths_out_new = [];
    for f_out = [string(fullpathGnhDFF), string(fullpathRfDFF)]
        %%
        [filedir, ~, fileext, ~, channel, postfix_out] = filenameParts(f_out);
        
        if(findstr(postfix_out, 'nohemo'))
            fullpath_new = fullfile(fullfolder_output, channel + "_unmixed_dFF" + fileext);
        else
            fullpath_new = fullfile(fullfolder_output, channel + "_dFF" + fileext);
        end
        
        copyfile(f_out, fullpath_new); paths_out_new = [paths_out_new, fullpath_new];
        
        movieSavePreviewVideos(fullpath_new, 'title', channel + " dFF")
    end

    fullpaths_mean = movieMeanTraces(paths_out_new, 'space', true);
    
    movieMeanTraceSpectrogram(paths_out_new(1), options_spectrogram);
    movieMeanTraceSpectrogram(paths_out_new(2), options_spectrogram);
end
%%


if(~strcmp(fullpathGin, fullpathGpreproc))
    delete(fullpathGin);
end
if(~strcmp(fullpathRin, fullpathRpreproc))
    delete(fullpathRin);
end

if(~strcmp(fullpathGm, fullpathGpreproc))
    delete(fullpathGm);
end
if(~strcmp(fullpathRm, fullpathRpreproc))
    delete(fullpathRm);
end

if(~strcmp(fullpathGcs, fullpathGpreproc))
    delete(fullpathGcs);
end
if(~strcmp(fullpathRcs, fullpathRpreproc))
    delete(fullpathRcs);
end

delete(fullpathGct);
delete(fullpathRct);

delete(fullpathGd);
delete(fullpathRd);

delete(fullpathGhp);
delete(fullpathRhp);

delete(fullpathGbl);
delete(fullpathRbl);

delete(fullpathGhemo);
delete(fullpathGnohemo);
%%

if(~strcmp(fullfolder_preprocessed, fullfolder_processing))
    allfiles = dir(fullfolder_processing);
    cellfun(@(n) movefile(fullfile(fullfolder_processing, n),  fullfolder_preprocessed), {allfiles(3:end).name})
end
%%

currentfile = mfilename('fullpath') + ".m"; %"C:\Users\Vasily\repos\VoltageImagingAnalysis\usersPipelines\Vasily\manual_processing\pipelines\pipeline_preprocessing.m"
copyfile(currentfile, fullfolder_preprocessed)

