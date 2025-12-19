        
basepath = "N:\GEVI_Wave\Analysis\Visual\mv3101\20251120\meas00\";
postfix = "cG_unmixed*_dFF"; 

file = dir(fullfile(basepath, "/*" +  postfix + ".h5"));
fullpath = fullfile(file.folder, file.name);

[filepath,name,~] = fileparts(fullpath);
%%

movieSaveSingleFrame(fullpath, ...
    'frametype', 'F0', 'mask', false,...
    'outdir', fullfile(filepath, "alignment_images"));
%%  
                    
movieAddMask(fullpath, fullfile(filepath, "alignment_images", name + "_maskManual.bmp"));
%%

allen_path = "..\analysis\allen_map\";
    
[filepath,name,ext] = fileparts(fullpath);  

if(~isfolder(fullfile(filepath, "alignment_images"))), mkdir(fullfile(filepath, "alignment_images")); end

copyfile(fullfile(allen_path, "allen_reference_image_scaled_toalign.png"), ... %  allen_reference_toalign or allen_reference_toalign_V1
          fullfile(filepath, "alignment_images", name + "_allen.png"))
copyfile(fullfile(allen_path, "allen_reference_points.txt"), ... % allen_reference_points or allen_reference_points_V1
          fullfile(filepath, "alignment_images", name + "_allen.txt"))
%%  

movieSaveSingleFrame(fullpath, ...  
    'frametype', 'std', 'outdir', fullfile(filepath, "alignment_images"),...
    'mask', false, 'skip', true);
%%

movieAddAllen(fullpath, fullfile(filepath, "alignment_images", name + "_allenManual.bmp"),...
    fullfile(filepath, "alignment_images", name + "_allen.txt"), fullfile(allen_path, "allenmap.mat"))
%%

files = dir(fullfile(basepath, "cR*.h5")); %"T:\GEVI_Wave\Analysis\Visual\m200M\20230501\meas0*"
% files = dir(fullfile('N:\GEVI_Wave\Analysis\Visual\cmm001mjr\20240423\*\', "*.h5")); %"T:\GEVI_Wave\Analysis\Visual\m200M\20230501\meas0*"
    
for i_f = 1:length(files)
   fullpath_copy = fullfile(files(i_f).folder, files(i_f).name);
   disp(fullpath_copy)
    
   movieCopyReference(fullpath_copy, fullpath, 'skip', false)
end
%%  

postfix_ref = "cR_dFF"; %
file_ref = dir(fullfile(basepath, "/*" +  postfix_ref + ".h5"));
fullpath_ref = fullfile(file_ref.folder, file_ref.name);
%%

% saves alignmet results to reference folder so that it can be reused
 
specs = rw.h5readMovieSpecs(fullpath);
    
fileroot_ref = specs.channel_id + "_c" + specs.mouse_id + "_" + ...
    string(datetime(specs.extra_specs('recordingDate')), 'yyyyMMdd') + "_" + ...
    strjoin(string(rw.h5getDatasetSize(fullpath, '/mov', [1,2])*specs.binning), 'x');

movieSaveSingleFrame(fullpath, ...
    'frametype', 'std', 'mask', false, 'format', ".h5",...
    'outdir', "P:\GEVI_Wave\MiceAlignment\", 'fileroot_out', fileroot_ref, ...
    'skip', false);

specs_ref = rw.h5readMovieSpecs(fullpath_ref);

fileroot_ref = specs_ref.mouse_id + "_c" + specs_ref.channel_id + "_" + ...
    string(datetime(specs_ref.extra_specs('recordingDate')), 'yyyyMMdd') + "_" + ...
    strjoin(string(rw.h5getDatasetSize(fullpath_ref, '/mov', [1,2])*specs_ref.binning), 'x');

movieSaveSingleFrame(fullpath_ref, ...
    'frametype', 'std', 'mask', false, 'format', ".h5",...
    'outdir', "P:\GEVI_Wave\MiceAlignment\", 'fileroot_out', fileroot_ref, ...
    'skip', false);
%%

movieSavePreviewVideos(fullpath, 'skip', false, 'mask', true)
% movieSavePreviewVideos(fullpath_ref, 'skip', false, 'mask', true)

