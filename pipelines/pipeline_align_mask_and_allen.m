        
basepath_preprocessed = "P:\GEVI_Wave\Preprocessed\";
basepath_analysis = "N:\GEVI_Wave\Analysis\";

recording_name = "Visual\mlk2501\20261003\meas00\";
patternG_in = "*-cG*_nohemoS_dFF.h5"; 
patternR_in = "*-cR*_dFF.h5"; 
% postfix = "cG_unmixed*_dFF"; 
%%

fullpathGdFF = copyFilesForAnalysis(recording_name, patternG_in, ...
    'new_name', "cG_unmixed_dFF", ...
    'basefolder_preprocessed', basepath_preprocessed, ...
    'basefolder_analysis', basepath_analysis,...
    'skip', true);

fullpathRdFF = copyFilesForAnalysis(recording_name, patternR_in, ...
    'new_name', "cR_dFF", ...
    'basefolder_preprocessed', basepath_preprocessed, ...
    'basefolder_analysis', basepath_analysis,...
    'skip', true);

copyfile( ...
    fullfile(basepath_preprocessed, recording_name, "alignment_images/"), ...
    fullfile(basepath_analysis,     recording_name, "alignment_images/"))
%%

[filepath,name,~] = fileparts(fullpathGdFF);

movieSaveSingleFrame(fullpathGdFF, ...
    'frametype', 'F0', 'mask', false,...
    'outdir', fullfile(filepath, "alignment_images"));
%%  
                    
movieAddMask(fullpathGdFF, fullfile(filepath, "alignment_images", name + "_maskManual.bmp"));
%%
    
% f0_lp = 10; wp = 1;
% options_lowpass = struct( 'attn', 1e4, 'rppl', 1e-1, 'skip', true);
% options_lowpass.filtersdir = "..\analysis\convolution_filters\";    
% options_lowpass.exepath = "..\analysis\c_codes\compiled\hdf5_movie_convolution.exe";    % to use compiled executable. 3-4 times faster
% 
% fullpathGlp = movieFilterLowpass(fullpathGdFF, f0_lp, wp, options_lowpass);
% 
% movieSaveSingleFrame(fullpathGlp, ...  
%     'frametype', 'std', 'outdir', fullfile(filepath, "alignment_images"),...
%     'mask', true, 'skip', true);
%%

movieSaveSingleFrame(fullpathGdFF, ...  
    'frametype', 'std', 'outdir', fullfile(filepath, "alignment_images"),...
    'mask', false, 'skip', true);
%%

allen_path = "..\analysis\allen_map\";
    
[filepath,name,ext] = fileparts(fullpathGdFF);  

if(~isfolder(fullfile(filepath, "alignment_images"))), mkdir(fullfile(filepath, "alignment_images")); end

copyfile(fullfile(allen_path, "allen_reference_image_scaled_toalign.png"), ... %  allen_reference_toalign or allen_reference_toalign_V1
          fullfile(filepath, "alignment_images", name + "_allen.png"))
copyfile(fullfile(allen_path, "allen_reference_points.txt"), ... % allen_reference_points or allen_reference_points_V1
          fullfile(filepath, "alignment_images", name + "_allen.txt"))
%%

movieAddAllen(fullpathGdFF, fullfile(filepath, "alignment_images", name + "_allenManual.bmp"),...
    fullfile(filepath, "alignment_images", name + "_allen.txt"), fullfile(allen_path, "allenmap.mat"))
%%

% movieAddCustomOutlines(fullpath, 'frametype', 'std')
%%

movieCopyReference(fullpathRdFF, fullpathGdFF, 'skip', false)
%%  

% saves alignmet results to reference folder so that it can be reused
 
specs = rw.h5readMovieSpecs(fullpathGdFF);
[sz_x, sz_y] = rw.h5getDatasetSize(fullpathGdFF, '/mov', [1,2]);
    
fileroot_ref = specs.mouse_id + "_c" + specs.channel_id + "_" + ...
    string(datetime(specs.extra_specs('recordingDate')), 'yyyyMMdd') + "_" + ...
    strjoin(string([sz_x, sz_y]*specs.binning), 'x');

movieSaveSingleFrame(fullpathGdFF, ...
    'frametype', 'std', 'mask', false, 'format', ".h5",...
    'outdir', "N:\GEVI_Wave\MiceAlignment\", 'fileroot_out', fileroot_ref, ...
    'skip', false);

specs_ref = rw.h5readMovieSpecs(fullpathRdFF);
[sz_x, sz_y] = rw.h5getDatasetSize(fullpathRdFF, '/mov', [1,2]);

fileroot_ref = specs_ref.mouse_id + "_c" + specs_ref.channel_id + "_" + ...
    string(datetime(specs_ref.extra_specs('recordingDate')), 'yyyyMMdd') + "_" + ...
    strjoin(string([sz_x, sz_y]*specs_ref.binning), 'x');

movieSaveSingleFrame(fullpathRdFF, ...
    'frametype', 'std', 'mask', false, 'format', ".h5",...
    'outdir', "N:\GEVI_Wave\MiceAlignment\", 'fileroot_out', fileroot_ref, ...
    'skip', false);
%%

movieSavePreviewVideos(fullpathGdFF, 'skip', false, 'mask', true)
% movieSavePreviewVideos(fullpath_ref, 'skip', false, 'mask', true)

