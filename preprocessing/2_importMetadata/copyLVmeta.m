function [copied_filelist,found_filelist,summary]=copyLVmeta(sourcepath,targetpath,varargin)
% HELP
% Copying LV generated files to a new destination. 
% In the Raw folder, assumes that everything except dcimg or h5 files (by mistake) is generated by LV.
% In the preprocessed folder, asssumes the whole content of 'LVmeta' can be copied. 
%
% SYNTAX
%[copied_filelistfound_filelist,summary]= copyLVmeta(sourcepath,targetpath) - use 3, etc.
%[copied_filelistfound_filelist,summary]= copyLVmeta(sourcepath,targetpath,'optionName',optionValue,...) - passing options using a 'Name', 'Value' paradigm frequently used by Matlab native functions.
%[copied_filelistfound_filelist,summary]= copyLVmeta(sourcepath,targetpath,'options',options) - passing options as a structure.
%
% INPUTS:
% - sourcepath - file path or a folder path. This function should flexibly parse either
% - targetpath - parent folder where data are going to be copied
%
% OUTPUTS:
% - copied_filelist - ...
% - found_filelist - ...
% - summary - %
% OPTIONS:
% - see below the section of code showing all possible input options and comments for their meaning. 

% HISTORY
% - 29-Jun-2020 17:04:49 - created by Radek Chrapkiewicz (radekch@stanford.edu)
% - 2020-10-06 22:54:14  - simplified content, summary and updated help RC


%% OPTIONS
options=struct; % add your options below 
options.subfolder='LVMeta';

%% VARIABLE CHECK 

if nargin>=3
options=getOptions(options,varargin(1:end)); % CHECK IF NUMBER OF THE OPTION ARGUMENT OK!
end
summary=initSummary(options); % saving orginally passed options to output them in the original form for potential next use

%% CORE
if isfile(sourcepath)
    folderpath=fileparts(sourcepath);
elseif isfolder(sourcepath)
    folderpath=sourcepath;
else
    error('This source path does not exist')
end

if ~strcmp(fileparts(targetpath),options.subfolder)
    targetfolder=fullfile(targetpath,options.subfolder);
else
    targetfolder=targetpath;
end
mkdirs(targetfolder);

% finding all files in the source folder 
found_filelist=rdir(folderpath);
table_files=struct2table(found_filelist);
excluded_ind=[];

disps(sprintf('Starting to copy files from %s to %s',folderpath, targetfolder));

for ii=1:length(found_filelist)
    [~,~,ext]=fileparts(found_filelist(ii).name);
    if strcmpi(ext,'.dcimg') ||strcmpi(ext,'.dcimg')
        excluded_ind=[excluded_ind,ii];
    else 
        copyfile(found_filelist(ii).name,targetfolder,'f');
    end
end

found_filelist(excluded_ind)=[];
nfound=length(found_filelist);
disps(sprintf('Copied %d files',nfound));
copied_filelist=rdir(targetfolder);
ntarget=length(copied_filelist);
summary.LVfolder=targetfolder; % - 2020-11-16 17:48:08 -   RC

if ntarget~=nfound
    disps('The number of found and copied files does not match')
end


summary=closeSummary(summary);
end  %%% END COPYLVMETA

