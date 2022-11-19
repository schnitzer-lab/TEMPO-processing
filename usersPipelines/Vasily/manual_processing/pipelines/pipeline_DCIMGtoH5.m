
% recording_name = "Visual\m16\20210319\meas01";
% 
% channels = ["G","R"];
% 
% binning = 8;
% maxRAM = 0.1;
% unaccounted_hardware_binning = 1; %For old recordings, hardware binning is not accounted for.
% 
% basefolder_raw = "\\VoltageRaw\DCIMG\GEVI_Wave\Raw\";
% basefolder_converted = "S:\GEVI_Wave\Preprocessed\";
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
                  
[h5path1,summary1] = ...
    convertRaw2Preproc1(char(fullfile(folder_raw, basefilename + channels(1) + extention)), ...
                        'binning', binning, 'useMovieSpecs', 1, ...
                        'expPath', char(folder_converted),...
                        'maxRAM', maxRAM*binning*binning, 'parallel', false, ...
                        'useDCIMGmex', true, 'skip', true, ...
                        'hardware_binning', unaccounted_hardware_binning, ...
                        'binning_postfix', true, 'binning_postfix', true);
%%

[h5path2,summary2] = ...
    convertRaw2Preproc1(char(fullfile(folder_raw, basefilename + channels(2) + extention)), ...
                        'binning', binning, 'useMovieSpecs', 1, ...
                        'expPath', char(folder_converted),...
                        'maxRAM', maxRAM*binning*binning, 'parallel', false,...
                        'useDCIMGmex', true, 'skip', true, ...
                        'hardware_binning', unaccounted_hardware_binning, ...
                        'binning_postfix', true);
%%

fullpaths_mean = movieMeanTraces([string(h5path1), string(h5path2)]);
    
movieMeanTraceSpectrogram(fullpaths_mean(1), 'f0', 2, 'timewindow', 10, 'df', 0.75, ...
    'processingdir', fullfile(folder_converted, "\processing\meanTraceSpectrogram\"));
movieMeanTraceSpectrogram(fullpaths_mean(2), 'f0', 2, 'timewindow', 10, 'df', 0.75, ...
    'processingdir', fullfile(folder_converted, "\processing\meanTraceSpectrogram\"));
%%

moviesCompareTimestamps(folder_converted);