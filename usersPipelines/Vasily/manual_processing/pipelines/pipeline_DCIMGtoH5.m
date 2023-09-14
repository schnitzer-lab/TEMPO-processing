
% recording_name = "Spontaneous\mCtrl12\20201122\meas01";
% 
% channels = ["G","R"];
% 
% basefolder_raw = "\\VoltageRaw\DCIMG\GEVI_Wave\Raw\"; %"R:\GEVI_Wave\Raw\";% 
% basefolder_converted = "S:\GEVI_Wave\Preprocessed\";
% 
% binning = 8;
% maxRAM = 0.1;
% unaccounted_hardware_binning = 1; %For old recordings, hardware binning is not accounted for.
%%

folder_raw = fullfile(basefolder_raw, recording_name);
folder_converted = fullfile(basefolder_converted, recording_name);
%%

if(isempty(dir(fullfile(folder_raw, '*G.dcimg'))))
    error("File not found: "+fullfile(folder_raw, '*G.dcimg'))
end

basefilename = dir(fullfile(folder_raw, '*G.dcimg')).name(1:(end-7));
extention = ".dcimg";
%%
           
options_dcimgtoh5 = struct('expPath', char(folder_converted), ...
    'binning', binning, 'hardware_binning', unaccounted_hardware_binning,...
    'parallel', false, 'maxRAM', maxRAM*binning*binning, 'skip', true, ...
    'useMovieSpecs', true, 'useDCIMGmex', true, 'binning_postfix', true); 

[h5path1,summary1] = ...
    convertRaw2Preproc1(char(fullfile(folder_raw, basefilename+channels(1)+extention)), ...
                        options_dcimgtoh5);
[h5path2,summary2] = ...
    convertRaw2Preproc1(char(fullfile(folder_raw, basefilename+channels(2)+ extention)), ...
                        options_dcimgtoh5);
%%

fullpaths_mean = movieMeanTraces([string(h5path1), string(h5path2)]);
    
movieMeanTraceSpectrogram(fullpaths_mean(1), 'f0', 2, 'timewindow', 5, 'df', 0.75, ...
    'processingdir', fullfile(folder_converted, "\processing\meanTraceSpectrogram\"));
movieMeanTraceSpectrogram(fullpaths_mean(2), 'f0', 2, 'timewindow', 5, 'df', 0.75, ...
    'processingdir', fullfile(folder_converted, "\processing\meanTraceSpectrogram\"));
%%

moviesCompareTimestamps(folder_converted);
%%

currentfile = mfilename('fullpath') + ".m"; 
copyfile(currentfile, folder_converted)