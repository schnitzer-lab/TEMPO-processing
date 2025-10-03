        
basepath = "N:\GEVI_Wave\Analysis\Isofluorane\m45\20211005\meas00\";
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

copyfile(fullfile(allen_path, "allen_reference_toalign.png"), ... %  allen_reference_toalign or allen_reference_toalign_V1
          fullfile(filepath, "alignment_images", name + "_allen.png"))
copyfile(fullfile(allen_path, "allen_reference_points.txt"), ... % allen_reference_points or allen_reference_points_V1
          fullfile(filepath, "alignment_images", name + "_allen.txt"))
%%  

movieSaveSingleFrame(fullfile(file.folder, "cG_unmixedTR_dFF.h5"), ...  
    'frametype', 'std', 'outdir', fullfile(filepath, "alignment_images"), 'mask', false);
%%

movieAddAllen(fullpath, fullfile(filepath, "alignment_images", name + "_allenManual.png"),...
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
 
specs = rw.h5readMovieSpecs (fullpath);
    
fileroot_ref = specs.getMouseId() + "_c" + specs.getChannelId() + "_" + ...
    string(datetime(specs.extra_specs('recordingDate')), 'yyyyMMdd') + "_" + ...
    strjoin(string(rw.h5getDatasetSize(fullpath, '/mov', [1,2])*specs.binning), 'x');

movieSaveSingleFrame(fullpath, ...
    'frametype', 'std', 'mask', false, 'format', ".h5",...
    'outdir', "P:\GEVI_Wave\MiceAlignment\", 'fileroot_out', fileroot_ref);

specs_ref = rw.h5readMovieSpecs(fullpath_ref);

fileroot_ref = specs_ref.getMouseId() + "_c" + specs_ref.getChannelId() + "_" + ...
    string(datetime(specs_ref.extra_specs('recordingDate')), 'yyyyMMdd') + "_" + ...
    strjoin(string(rw.h5getDatasetSize(fullpath_ref, '/mov', [1,2])*specs_ref.binning), 'x');

movieSaveSingleFrame(fullpath_ref, ...
    'frametype', 'std', 'mask', false, 'format', ".h5",...
    'outdir', "P:\GEVI_Wave\MiceAlignment\", 'fileroot_out', fileroot_ref);
%%

movieSavePreviewVideos(fullpath, 'skip', false, 'mask', true)
% movieSavePreviewVideos(fullpath_ref, 'skip', false, 'mask', true)

