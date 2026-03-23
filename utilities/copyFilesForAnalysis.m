
function [fullpath_out,fullpaths_out] = copyFilesForAnalysis(recording_name, pattern, name_new, varargin)
%%
    % patterns_tomove = ["*-cG*_nohemoS_dFF.h5"; "*-cR*_dFF.h5"];
    % names_new = ["cG_unmixed_dFF", "cR_dFF"];

    options = parseInputs(varargin{:});

    %%
    
    path_from = fullfile(options.basefolder_preprocessed, recording_name);
    path_to = fullfile(options.basefolder_analysis, recording_name);
       
    file = dir(fullfile(path_from, pattern));
    
    if(length(file) > 1), error("more than one match: " + fullfile(path_from, pattern)); end
    if(isempty(file)), error("no matches: " + fullfile(path_from, pattern)); end
    
    [~, filename, ~] = fileparts(file.name);
    
    all_files = dir(fullfile(path_from, '**', [filename '*']));
    %%

    fullpaths_out = repelem("", length(all_files));
    for i_f = 1:length(all_files)
        fullpaths_out(i_f) = copyfileWithRelativePath(...
            fullfile(all_files(i_f).folder, all_files(i_f).name), ...
            path_to, path_from, filename, name_new, options.skip);
    end
    
    fullpath_out = fullpaths_out(1); 
end
%%

function options = parseInputs(varargin)
    
    p = inputParser();

    p.addParameter('basefolder_preprocessed', ...
        "F:\GEVI_Wave\Preprocessed", @(s) isstring(s)|ischar(s));
    p.addParameter('basefolder_analysis', ...
        "T:\GEVI_Wave\Analysis", @(s) isstring(s)|ischar(s));
   
    p.addParameter('skip', true, @(x) (x==true)|(x==false));

    p.parse(varargin{:});
    options = p.Results;
end