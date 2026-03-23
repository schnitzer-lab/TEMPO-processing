% also needs matlab_utils

basefolder_analysis = "N:\GEVI_Wave\Analysis\";  

% T: is an M.2 hardrive with fast read/write
% only temporary data storage during analysis, 
% periodically all data is deleted!
basefolder_temp = "T:\GEVI_Wave\Analysis\"; 
%%

recording_name = "Visual\m48\20210824\meas00";
filename_in1 = "cG_unmixed_dFF.h5";
filename_in2 = "cR_dFF.h5";

fullpath_unmixed1 = fullfile(basefolder_analysis, recording_name, filename_in1);
fullpath_unmixed2 = fullfile(basefolder_analysis, recording_name, filename_in2);

fullpath_in1 = fullfile(basefolder_temp, recording_name, filename_in1);
fullpath_in2 = fullfile(basefolder_temp, recording_name, filename_in2);

%%
% unrelated - in case you need a set or recordings to loop through

files = [dir(basefolder_analysis + "Visual\m48\20210824\meas*")]; 
recording_names = arrayfun(@(f) string(fullfile(f.folder, f.name)), files);
recording_names = erase(recording_names, basefolder_analysis);
%%
% copy from storage to processing hard drive

folder_analysis = fullfile(basefolder_analysis, recording_name);
folder_temp = fullfile(basefolder_temp, recording_name);

if(~strcmp(folder_analysis, folder_temp))
    disp("copying data to: "+folder_temp)
    if(~isfolder(folder_temp)) mkdir(folder_temp); end
    if(~isfile(fullpath_in1)) copyfile(fullpath_unmixed1, fullpath_in1); end
    if(~isfile(fullpath_in2)) copyfile(fullpath_unmixed2, fullpath_in2); end
end
%%
% Extract traces for a brain region (pre-aligned to allen brain map)

fullpath1_region = movieExtractRegionTrace(fullpath_in1, "V1");
fullpath2_region = movieExtractRegionTrace(fullpath_in2, "V1");
%%
% Read extracted traces (1x1xNt movies)

[M1, s1] = rw.h5readMovie(fullpath1_region);
[M2, s2] = rw.h5readMovie(fullpath2_region);

m1 = squeeze(M1);
m2 = squeeze(M2);
%%

fig = plt.getFigureByName("V1 traces");
plt.tracesComparison([m1,m2], 'spacebysd', 4, 'fps', s1.getFps(), 'fw', 0.2, ...
    'labels', ["voltage", "reference"]);

subplot(2,1,1);
hold on;
plot((0:length(m1))/s1.getFps(), (s1.getTTLTrace(length(m1)+1) - 5)*std(m1) )
hold off;

%%
% implemented all-in-one analysis for brain region traces w respect to
% stimulus ttl

fullpath_stim1 = moviePlotTraceStim(fullpath_in1, "V1", 'iti_scale', 2.5, 'skip', false);
fullpath_stim2 = moviePlotTraceStim(fullpath_in2, "V1", 'iti_scale', 2.5, 'skip', false);
%%
% temporal averaging with respect to stimulus ttl

fullpath1_trialav = movieTrialAverage(fullpath_in1);
%%
% save as a video

specs_av = rw.h5readMovieSpecs(fullpath1_trialav);
nT = rw.h5getDatasetSize(fullpath1_trialav, '/mov',3);
movieSavePreviewVideos(fullpath1_trialav, ...
    'ranges', (1:nT)+(specs_av.timeorigin-1), ...
    'postfixes', "",...
    'mask', true, 'skip', false, 'saturate', 0.002,...
    'title', 'trial_av')


