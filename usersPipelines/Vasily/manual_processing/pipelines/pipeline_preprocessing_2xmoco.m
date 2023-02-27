    
% parpool('Threads');
%%

recording_name = "Visual\m40\20210824\meas00";

channels = ["G","R"];

binning = 8;
maxRAM = 0.1;
unaccounted_hardware_binning = 1; %For old recordings, hardware binning is not accounted for.

basefolder_raw = "\\VoltageRaw\DCIMG\GEVI_Wave\Raw\"; %"R:\GEVI_Wave\Raw\";%
basefolder_converted = "S:\GEVI_Wave\Preprocessed\";
basefolder_processing = "T:\GEVI_Wave\Preprocessed\";
basefolder_output = "P:\GEVI_Wave\Preprocessed\";
%%

folder_raw = fullfile(basefolder_raw, recording_name);
folder_output = fullfile(basefolder_output, recording_name);
folder_processing = fullfile(basefolder_processing, recording_name);
folder_converted = fullfile(basefolder_converted, recording_name);
%%

if(isempty(dir(fullfile(folder_raw, '*G.dcimg'))))
    error("File not found: "+fullfile(folder_raw, '*G.dcimg'))
end

basefilename = dir(fullfile(folder_raw, '*G.dcimg')).name(1:(end-7));
extention = ".dcimg";
%%
                  
final_file = fullfile(folder_output,...
    basefilename + channels(2) + "_bin" + string(binning) + "_mc_reg.h5");
if(isfile(final_file)) error("File exists, ending " + final_file); end
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
    
movieMeanTraceSpectrogram(fullpaths_mean(1), 'f0', 2, 'timewindow', 10, 'df', 0.75, ...
    'processingdir', fullfile(folder_converted, "\processing\meanTraceSpectrogram\"));
movieMeanTraceSpectrogram(fullpaths_mean(2), 'f0', 2, 'timewindow', 10, 'df', 0.75, ...
    'processingdir', fullfile(folder_converted, "\processing\meanTraceSpectrogram\"));
%%

moviesCompareTimestamps(folder_converted);
%%

[~,fn1, ext] = fileparts(h5path1); h5path1_p = fullfile(folder_processing, [fn1,ext]);
[~,fn2, ext] = fileparts(h5path2); h5path2_p = fullfile(folder_processing, [fn2,ext]);

if(~strcmp(folder_converted, folder_processing))
    disp("copying data to: "+folder_processing)
    if(~isfolder(folder_processing)) mkdir(folder_processing); end
    if(~isfile(h5path1_p)) copyfile(h5path1,  h5path1_p); end
    if(~isfile(h5path2_p)) copyfile(h5path2,  h5path2_p); end
    copyfile(fullfile(folder_converted, "LVMeta"),  fullfile(folder_processing,"LVMeta"))
    copyfile(fullfile(folder_converted, "processing"),  fullfile(folder_processing,"processing"))
end
%%

[h5path1_mc, shiftsfile1] = movieSimpleMoco(h5path1_p, 'impute_nan', true);
[h5path2_mc, shiftsfile2] = movieSimpleMoco(h5path2_p, 'impute_nan', true);
%%

[h5path1_reg, h5path2_reg, summary_or] = regMovies(char(h5path1_mc), char(h5path2_mc), ...
     'BandPass', true, 'BandPx', [2,10], 'interp', 'linear', ...
     'docrop', false, 'maxRAM', maxRAM, 'skip', true);
    %%

s = rw.h5readMovieSpecs(h5path1_mc); 
s.AddToHistory('regMovies');
rw.h5saveMovieSpecs(h5path1_reg, s);

s = rw.h5readMovieSpecs(h5path2_mc); 
s.AddToHistory('regMovies');
rw.h5saveMovieSpecs(h5path2_reg, s);
%%

% h5path2_imp = movieImputeNaNS(h5path2_reg);
%%

movieMeanTraces([string(h5path1_mc), string(h5path2_reg)]);
movieMakeMask(h5path1_mc); movieMakeMask(h5path2_reg);
%%

% if(~strcmp(h5path2_imp, h5path2_reg)) delete(h5path2_reg); end
if(~strcmp(h5path1_reg, h5path1_mc)) delete(h5path1_reg); end
if(~strcmp(h5path2_mc, h5path2_reg)) delete(h5path2_mc); end
if(~strcmp(h5path1_p,  h5path1))     delete(h5path1_p); end
if(~strcmp(h5path2_p,  h5path2))     delete(h5path2_p); end
%%

if(~strcmp(folder_output, folder_processing))
    disp("copying data to: "+folder_output)
    allfiles = dir(folder_processing);
    cellfun(@(n) movefile(fullfile(folder_processing, n),  fullfile(folder_output, n)), {allfiles(3:end).name})
end
%%

currentfile = mfilename('fullpath') + ".m"; 
copyfile(currentfile, folder_output)