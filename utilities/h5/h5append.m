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

% HISTORY
% - 20-06-14 02:43:56 - created by Radek Chrapkiewicz (radekch@stanford.edu)
% - 2020-06-15 18:48:54 RC - dataset as the 3rd argument 
% - 2021-04-27 15:06:22 - shortened code for summary, names adapted to Matlab style   RC

%% CONSTANTS (never change, use OPTIONS instead)


%% OPTIONS (Biafra style, type 'help getOptions' for details) or: https://github.com/schnitzer-lab/VoltageImagingAnalysis/wiki/'options':-structure-with-function-configuration
options.contact='Radek Chrapkiewicz (radekch@stanford.edu)';
options.dataset='mov'; %default dataset tname
options.verbose=0;

movieSize=size(movie); % unsually checking something here to define default chunk size
if length(movieSize)<3
    movieSize=[movieSize,1];
end
frame_size=movieSize(1:2);
options.ChunkSize=[frame_size, 1];  % you may consider finer chunking in space for tile loading, but this is not tested % 2020-06-14 03:08:02 RC

%% VARIABLE CHECK 

if nargin>=3
    options.dataset=varargin{1};
end

if nargin>=4
options=getOptions(options,varargin(2:end));
end
summary=initSummary(options); % saving orginally passed options to output them in the original form for potential next use




%% CORE
dataset_name=options.dataset;
if dataset_name(1)~='/'
    dataset_name=['/', dataset_name];
end

if ~isfile(filename)
    dataset_ind=0;
else    
    dataset_ind=isDataset(filename,dataset_name);
end

if ~dataset_ind % dataset does not exist
    disp('Creating new dataset')
    h5create(filename,dataset_name,[frame_size, Inf],'Datatype',class(movie),'ChunkSize',options.ChunkSize);
    h5write(filename, dataset_name, movie, [1,1,1], movieSize); % movie size needs to have 3 elements RC
else
    disp('Dataset already exists, appedning')
    [dataset_ind,info_h5]=isDataset(filename,dataset_name);
    h5currentsize=info_h5.Datasets(dataset_ind).Dataspace.Size;
    h5write(filename,dataset_name, movie,[1,1,h5currentsize(3)+1],movieSize); % movie size needs to have 3 elements RC
end


disp('H5 file saved')

info_h5=h5info(filename);


%% CLOSING

summary=closeSummary(summary);
movie_info=whos('movie');
summary.movieMB=movie_info.bytes/2^20;
summary.MB_per_sec=summary.movieMB/summary.executionDuration;



function disp(string) %overloading disp for this function 
    if options.verbose
        fprintf('%s h5append: %s\n', datetime('now'),string);
    end
end


end

function [datasetInd,infoH5]=isDataset(h5filepath,datasetName)
% returns 0 if does not exist
% returns positive integer with the index of corresponding h5 dataset
% by RC
infoH5=h5info(h5filepath);
datasetInd=0; % not exist - on default

if datasetName(1)=='/'
    datasetName=datasetName(2:end);
end

for ii=1:length(infoH5.Datasets)
    if strcmp(infoH5.Datasets(ii).Name,datasetName)
        datasetInd=ii;
        break;
    end
end
        

end