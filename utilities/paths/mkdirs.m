function mkdirs(foldersPaths)
% HELP MKDIRS.M
% Creates folder or multiple folders, if they don't exist already
% SYNTAX
%[output_arg1,summary]= mkdirs(foldersPaths)
% INPUTS:
% - foldersPaths - char array or cell of char arrays

% HISTORY
% - 15-Sep-2020 09:46:32 - created by Radek Chrapkiewicz (radekch@stanford.edu)

if ischar(foldersPaths)
    createFolder(foldersPaths);
elseif iscell(foldersPaths)
    for iCell=1:length(foldersPaths)
        folder=foldersPaths{iCell};
        createFolder(folder);
    end
else 
    error('Input type %s not supported',class(foldersPaths));
end
    

end

function createFolder(folder)
        if ~isfolder(folder)
        mkdir(folder)
        end
end