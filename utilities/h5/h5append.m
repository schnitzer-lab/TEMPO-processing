function [info_h5,summary]=h5append(filename,movie,varargin)
% HELP
% Append (or create) h5 file dataset with movie chunks. For other data datatypes use (compatible) 'h5save'.
% SYNTAX
%[info,summary]= h5append(filename,movie) 
%[info,summary]= h5append(filename,movie,dataset) 
%[info,summary]= h5append(filename,movie,dataset,'optionName',optionValue,...) - passing options using a 'Name', 'Value' paradigm frequently used by Matlab native functions.
%[info,summary]= h5append(filename,movie,dateset,'options',options) - passing options as a structure.
%
% INPUTS:
% - filename - full path to h5 file
% - movie - 3d matrix you want to save
% - dataset - name of the dataset to e.g. 'mov'
%
% OUTPUTS:
% - info_h5 - infor about created h5 files
% - summary - summary of execution and initial options. 
% OPTIONS:
% - see below the section of code showing all possible input options and comments for their meaning. 
%
% HISTORY
% - 20-06-14 02:43:56 - created by Radek Chrapkiewicz (radekch@stanford.edu)
% - 2020-06-15 18:48:54 RC - dataset as the 3rd argument 
%
% ISSUES
% #1 - 
%
% TODO
% *1 - 

%% CONSTANTS (never change, use OPTIONS instead)


%% OPTIONS (Biafra style, type 'help getOptions' for details) or: https://github.com/schnitzer-lab/VoltageImagingAnalysis/wiki/'options':-structure-with-function-configuration
options.contact='Radek Chrapkiewicz (radekch@stanford.edu)';
options.dataset='mov'; %default dataset tname
options.verbose=1;

movie_size=size(movie); % unsually checking something here to define default chunk size
if length(movie_size)<3
    movie_size=[movie_size,1];
end
frame_size=movie_size(1:2);
options.ChunkSize=[frame_size, 1];  % you may consider finer chunking in space for tile loading, but this is not tested % 2020-06-14 03:08:02 RC

%% VARIABLE CHECK 

if nargin>=3
    options.dataset=varargin{1};
end

if nargin>=4
options=getOptions(options,varargin(2:end)); % CHECK IF NUMBER OF THE OPTION ARGUMENT OK!
end
input_options=options; % saving orginally passed options to output them in the original form for potential next use


%% Summary preparation
summary.function_path=mfilename('fullpath');
summary.execution_started=datetime('now');
summary.execution_duration=tic;
summary.movie_size=movie_size;


%% CORE
dataset_name=options.dataset;
if dataset_name(1)~='/'
    dataset_name=['/', dataset_name];
end

if ~isfile(filename)
    dataset_ind=0;
else    
    dataset_ind=exist_dataset(filename,dataset_name);
end

if ~dataset_ind % dataset does not exist
    disp('Creating new dataset')
    h5create(filename,dataset_name,[frame_size, Inf],'Datatype',class(movie),'ChunkSize',options.ChunkSize);
    h5write(filename, dataset_name, movie, [1,1,1], movie_size); % movie size needs to have 3 elements RC
else
    disp('Dataset already exists, appedning')
    [dataset_ind,info_h5]=exist_dataset(filename,dataset_name);
    h5currentsize=info_h5.Datasets(dataset_ind).Dataspace.Size;
    h5write(filename,dataset_name, movie,[1,1,h5currentsize(3)+1],movie_size); % movie size needs to have 3 elements RC
end


disp('H5 file saved')

info_h5=h5info(filename);


%% CLOSING
summary.input_options=input_options; % passing input options separately so they can be used later to feed back to function input.
summary.execution_duration=toc(summary.execution_duration);
summary.filename=filename;
movie_info=whos('movie');
summary.movieMB=movie_info.bytes/2^20;
summary.MB_per_sec=summary.movieMB/summary.execution_duration;

function disp(string) %overloading disp for this function 
    if options.verbose
        fprintf('%s h5append: %s\n', datetime('now'),string);
    end
end


end

function [dataset_ind,info_h5]=exist_dataset(h5_file,datasetname)
% returns 0 if does not exist
% returns positive integer with the index of corresponding h5 dataset
% by RC
info_h5=h5info(h5_file);
dataset_ind=0; % not exist - on default

if datasetname(1)=='/'
    datasetname=datasetname(2:end);
end

for ii=1:length(info_h5.Datasets)
    if strcmp(info_h5.Datasets(ii).Name,datasetname)
        dataset_ind=ii;
        break;
    end
end
        

end