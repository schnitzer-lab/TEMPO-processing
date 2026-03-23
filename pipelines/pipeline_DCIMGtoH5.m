% 
% clear; 
% close all;
% warning on;
% if(isempty(gcp('nocreate'))), parpool('Threads'); end 
% 
% diary(fullfile("N:\GEVI_Wave\Logs", ...
%         strcat(string(datetime('now','Format','yyyyMMddHHmmss')),'_',mfilename(),'.log')));
% %
% 
% recording_name = "Visual\m48\20210824\meas00";
% 
% channels = ["G","R"];
% 
% basefolder_raw = "R:\GEVI_Wave\Raw\";% 
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

% movieSaveSingleFrame(h5path2, 'frametype', 'median', 'frames_range',  [1,1000]+100);
movieSaveSingleFrame(h5path1, 'frametype', 'median', 'frames_range', -[1000,1]-100);
%%

fullpaths_mean = movieMeanTraces([string(h5path1), string(h5path2)]);
    
movieMeanTraceSpectrogram(fullpaths_mean(2), 'frange', [2, Inf], 'timewindow', 5, 'fw', 0.75, ...
    'processingdir', fullfile(folder_converted, "\processing\meanTraceSpectrogram\"));
movieMeanTraceSpectrogram(fullpaths_mean(1), 'frange', [2, Inf], 'timewindow', 5, 'fw', 0.75, ...
    'processingdir', fullfile(folder_converted, "\processing\meanTraceSpectrogram\"));
%%

moviesCompareTimestamps(folder_converted);
%%

currentfile = mfilename('fullpath') + ".m"; 
copyfile(currentfile, folder_converted)