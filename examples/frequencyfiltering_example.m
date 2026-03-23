

basefolder_analysis = "N:\GEVI_Wave\Analysis\";  
recording_name = "Visual\m48\20210824\meas00";
filename_in1 = "cG_unmixed_dFF.h5";

fullpath_in1 = fullfile(basefolder_analysis, recording_name, filename_in1);
%%


% Make sure that filter resonable, if not increase wp or decrease attn;
options_bandpass = struct( 'attn', 1e4, 'rppl', 1e-2,  'skip', true, ...
    'filtersdir', "P:\GEVI_Wave\ConvolutionFilters\"); 
f0 = 6;
wp = 2.5;

% to use compiled executable. 3-4 times faster
% options_bandpass.exepath = "..\analysis\c_codes\compiled\hdf5_movie_convolution.exe");   

% frequency filter whole movie at a single pixel level
% movieFilterExternalHighpass and movieFilterExternalLowpass also exist
fullpath_bp = movieFilterBandpass(fullpath_in1, f0, wp, options_bandpass);

% save a preview video of a filtered movie
movieSavePreviewVideos(fullpath_bp, 'title', 'filtered', 'mask', true)

