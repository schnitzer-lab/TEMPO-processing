function fullpath_out = copyfileWithRelativePath(fullpath_in, folder_new, ...
    folder_old, filename_start_old, filename_start_new)
    
    if(nargin < 3), folder_old = fileparts(fullpath_in); end
    if(nargin < 4) 
        filename_start_new = ''; 
        filename_start_old = ''; 
    end
    
    path_rel = erase(fullpath_in, folder_old);
    [folder_rel, filename, ext] =  fileparts(path_rel);
    filename_new = filename_start_new + erase(filename, filename_start_old);
    
    fullpath_out = fullfile(folder_new, folder_rel, filename_new+ext);

    if(~isfolder(fileparts(fullpath_out))), mkdir(fileparts(fullpath_out)); end

    copyfile(fullpath_in, fullpath_out);
end