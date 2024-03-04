    
% parpool('Threads');
%%

% recording_name = "Spontaneous\mv0104\20230815\meas04";%"Spontaneous\mv0104\20230815\meas04" %(short 22s recording for tests);
% postfix_in1 = "cG_bin8";
% postfix_in2 = "cR_bin8";
% 
% basefolder_converted = "S:\GEVI_Wave\Preprocessed\";
% basefolder_processing = "T:\GEVI_Wave\Preprocessed\";
% basefolder_output = "P:\GEVI_Wave\Preprocessed\";
% 
% shifts0 = [20,0]; % pix, between R and G channel due to cameras misalignment
%
% maxRAM = 0.1;
% skip_if_final_exists = true;
%%

folder_converted = fullfile(basefolder_converted, recording_name);
folder_processing = fullfile(basefolder_processing, recording_name);
folder_output = fullfile(basefolder_output, recording_name);
%%

file1 = dir(fullfile(folder_converted, "/*" + postfix_in1 + ".h5"));
file2 = dir(fullfile(folder_converted, "/*" + postfix_in2 + ".h5"));

if(isempty(file1)) 
    error("Preprocessing:fileNotFound", "Green channel .h5 file not found")
elseif isempty(file2)
    error("Preprocessing:fileNotFound", "Red channel .h5 file not found")
end
%%
               

fullpathGconv = fullfile(file1.folder, file1.name);
fullpathRconv = fullfile(file2.folder, file2.name);

[~, ~, ext1, basefilename1, channel1, ~] = filenameParts(fullpathGconv);
fullpathGin = fullfile(folder_processing, file1.name);%basefilename1+channel1+"_preprocessed"+ext1);
[~, ~, ext2, basefilename2, channel2, ~] = filenameParts(fullpathRconv);
fullpathRin = fullfile(folder_processing, file2.name);%basefilename2+channel2+"_preprocessed"+ext2);
%%

[filedir, filename, fileext, basefilename, channel, ~] = filenameParts(fullpathRconv);
final_file = fullfile(folder_output, filename + "*_mc_reg.h5");
result = dir(final_file);
if(~isempty(result)) 
    if(skip_if_final_exists)
        error("Final file exists, ending " + fullfile(result.folder, result.name)); 
    else
        warning("Final file exists and will be owerwritten " + fullfile(result.folder, result.name)); 
    end
end
%%

% moviesCompareTimestamps(folder_converted);
%%

if(~strcmp(folder_converted, folder_processing))
    disp("copying data to: "+folder_processing)
    if(~isfolder(folder_processing)) mkdir(folder_processing); end
    if(~isfile(fullpathGin)) copyfile(fullpathGconv,  fullpathGin); end
    if(~isfile(fullpathRin)) copyfile(fullpathRconv,  fullpathRin); end
    copyfile(fullfile(folder_converted, "LVMeta"),  fullfile(folder_processing,"LVMeta"))
    copyfile(fullfile(folder_converted, "processing"),  fullfile(folder_processing,"processing"))
end
%%

% h5path1_p = movieExtractFrames(h5path1, [1500, 1800]*120, 'outdir', folder_processing);
% h5path2_p = movieExtractFrames(h5path2, [1500, 1800]*120, 'outdir', folder_processing);
%%

[h5path1_mc, shiftsfile1] = movieSimpleMoco(fullpathGin, 'impute_nan', true);
[h5path2_mc, shiftsfile2] = movieSimpleMoco(fullpathRin, 'impute_nan', true);
%%

warning('fix regMovies!')
options_reg= struct('BandPass', true, 'BandPx', [2,10], 'interp', 'linear', ...
     'docrop', false, 'maxRAM', maxRAM, 'skip', true, 'shifts0', shifts0); 
[h5path1_reg, h5path2_reg, summary_or] = ...
    regMovies(char(h5path1_mc), char(h5path2_mc), options_reg);
delete(h5path1_reg)
%%

s = rw.h5readMovieSpecs(h5path2_mc); 
s.AddToHistory('regMovies', ...
    mergeStructs({struct('fixed', char(h5path1_mc), 'moving', char(h5path2_mc)), ...
        options_reg, struct('callDateTimeAutomatic', char(datetime()), 'callFilenameAutomatic', 'VoltageImagingAnalysis\preprocessing\4_registrationChAlign\regMovies.m')}));
rw.h5saveMovieSpecs(h5path2_reg, s);
%%

% h5path2_imp = movieImputeNaNS(h5path2_reg);
%%

movieMeanTraces([string(h5path1_mc), string(h5path2_reg)]);
movieMakeMask(h5path1_mc); movieMakeMask(h5path2_reg);
%%

% if(~strcmp(h5path2_imp, h5path2_reg)) delete(h5path2_reg); end
if(~strcmp(h5path2_mc, h5path2_reg)) delete(h5path2_mc); end
if(~strcmp(fullpathGin,  fullpathGconv))     delete(fullpathGin); end
if(~strcmp(fullpathRin,  fullpathRconv))     delete(fullpathRin); end
%%

if(~strcmp(folder_output, folder_processing))
    disp("moving preprocessed data to: "+folder_output)
    if(~isdir(folder_output)) mkdir(folder_output); end
    allfiles = dir(folder_processing);
    cellfun(@(n) movefile(fullfile(folder_processing, n),  fullfile(folder_output, n)), ...
        {allfiles(3:end).name})
end
%%

currentfile = mfilename('fullpath') + ".m"; 
copyfile(currentfile, folder_output)