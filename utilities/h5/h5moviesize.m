function [msize,summary]=h5moviesize(filepath,varargin)
% HELP
% Find a dataset '/mov' in h5 file and reads the matrix size. 
% SYNTAX
%[msize,summary]= h5moviesize(filepath) - use 2, etc.
%[msize,summary]= h5moviesize(filepath,'optionName',optionValue,...) - passing options using a 'Name', 'Value' paradigm frequently used by Matlab native functions.
%[msize,summary]= h5moviesize(filepath,'options',options) - passing options as a structure.
%
% INPUTS:
% - filepath - ...
%
% OUTPUTS:
% - msize - ...
% - summary - %
% OPTIONS:
% - see below the section of code showing all possible input options and comments for their meaning. 
%
% HISTORY
% - 29-Jun-2020 21:46:20 - created by Radek Chrapkiewicz (radekch@stanford.edu)
%
% ISSUES
% #1 - issue 1
%
% TODO
% *1 - get the first working version of the function!


%% OPTIONS (Biafra style, type 'help getOptions' for details) or: https://github.com/schnitzer-lab/VoltageImagingAnalysis/wiki/'options':-structure-with-function-configuration
options=struct; % add your options below 
options.dataset='mov';

%% VARIABLE CHECK 


if nargin>=2
options=getOptions(options,varargin(1:end)); % CHECK IF NUMBER OF THE OPTION ARGUMENT OK!
end
input_options=options; % saving orginally passed options to output them in the original form for potential next use
if options.dataset(1)=='/'
    options.dataset=options.dataset(2:end);
end
    

%% PATHS

%% Summary preparation
summary.function_path=mfilename('fullpath');
summary.execution_started=datetime('now');
summary.execution_duration=tic;


%% CORE
%The core of the function should just go here.

info=h5info(filepath);

movie_dataset=[];
for dataset_idx=1:length(info.Datasets)
    if strcmp(info.Datasets(dataset_idx).Name,options.dataset)
        movie_dataset=dataset_idx;
        break;
    end
end
    
if isempty(movie_dataset)
    error('Dataset %s not found in %s',options.dataset, filepath);
end

msize=info.Datasets(movie_dataset).Dataspace.Size;

summary.bytes_per_px=info.Datasets(movie_dataset).Datatype.Size;

summary.finfo=rdir(filepath);
summary.filesizeMB=summary.finfo(1).bytes/2^20;


%% CLOSING
summary.input_options=input_options; % passing input options separately so they can be used later to feed back to function input.
summary.execution_duration=toc(summary.execution_duration);


end  %%% END H5MOVIESIZE
