% also needs matlab_utils

basefolder_analysis = "N:\GEVI_Wave\Analysis\";  
recording_name = "Visual\m48\20210824\meas00";
filename_in1 = "cG_unmixed_dFF.h5";
filename_in2 = "cR_dFF.h5";

fullpath_in1 = fullfile(basefolder_analysis, recording_name, filename_in1);
fullpath_in2 = fullfile(basefolder_analysis, recording_name, filename_in2);
%%

% reading movie array /movie into M and /specs into specs. 
[M1, specs] = rw.h5readMovie(fullpath_in1);
[M2, ~]     = rw.h5readMovie(fullpath_in2);
%%
% spatial plot of the temporal variance in the voltage movie 
% (~bulk activity power) and pre-aligned brain regions map

Mstd = std(M1(:,:,1:5000),[],3); %only 5000 frames for illustration

plt.getFigureByName("F0");

im1 = imshow(plt.saturate(Mstd, 0.01), []); colormap(plt.redblue); 
set(im1, 'AlphaData', specs.getMask());

hold on;
plt.outlines(specs.getAllenOutlines(), ...
    [0, size(M1,2)], [0, size(M1,1)], 'color', 'green')
hold off;
%%
% spatially-averaged time traces with some pre-computed masking applied 
% (to exclude areas outside the brain surface / large vessels)

plt.getFigureByName("traces");

m1 = squeeze(mean(M1.*specs.getMaskNaN(), [1,2], 'omitnan'));
m2 = squeeze(mean(M2.*specs.getMaskNaN(), [1,2], 'omitnan'));

plt.tracesComparison([m1,m2], 'fps', specs.getFps(), 'fw', 0.2, ...
    'f0', specs.getFrequencyRange(1), 'spacebysd', 4, 'labels', ["voltage", "ref"])
%%
