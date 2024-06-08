function [voltage_paths_structure,options]=voltPaths(varargin)
% EXAMPLE USE WITH ARGUMENTS
%[voltage_paths_structure,options]= voltPaths() - analyzing and generating
%the path structure for the parent working directory (pwd)
%[voltage_paths_structure,options]= voltPaths(folder_path) - use 2, etc.
%[voltage_paths_structure,options]= voltPaths(folder_path,options) - use 3 with options
%
% HELP
% Generating paths for pipeline for voltage imageing analysis. As an input
% provide your current file folder, or on default, if no input arguments
% provided, function takes the parent working directory.

% HISTORY
% - 20-05-19 15:10:24 - created by Radek Chrapkiewicz (radekch@stanford.edu)
%
% ISSUES
% #1 - issue 1
%
% TODO
% *1 - get the first working version of the function!




%% CONSTANTS (never change, use OPTIONS instead)
DEBUG_THIS_FILE=false;
DEFAULT_UNIX_USER='Generic';


%% OPTIONS (Biafra style, type 'help getOptions' for details)
options=struct;
if ispc
    options.User=getenv('username'); % default User on Windows is just your current username, but set the option if you want it to be different.
else
    options.User=DEFAULT_UNIX_USER;
end

%
options.RecordingDrives={'B:\','D:\','E:\'}; % drives where you stream data directly from the cameras (dcimg files and raw metadata)
options.AnalysisDrive='F:\'; % drive where you backup the data right after the recording
options.ProcessedStorageDrive='F:\'; % drive where you permanently storred preprocessed and analysis data but not the raw, dcimg files
options.ColdStorageDrives={'M:\','N:\','O:\','P:\','X:\','U:\','Q:\'}; % cold storage drive in the priority order

options.OutputPathsTypes={'DCIMGOriginal','DCIMGTemporary',...
    'PreprocessingTemporary','PreprocessingStorage','AnalysisTemporary','AnalysisStorage','ColdDCIMGStorage'};

options.AllowedDrives=horzcat(options.RecordingDrives,options.AnalysisDrive,options.ProcessedStorageDrive,options.ColdStorageDrives); % all drives that are allowe for the analysis

options.AllowedProjectNames={'GEVI_Wave','GEVI_Spike','Calibration','GECI','Control','Monique'};



options.ProcessingStages={'Raw','Preprocessed','Analysis'}; % exact spelling of the processing stages to be expected

options.FolderStructure={'Drive','Project','Stage','Experiment','Mouse','Date','Measurement'};
options.DateIndex=6; % 6th folder in the hierarchy
options.ProjectIndex=2; % 2nd folder in the hierarchy
options.StageIndex=3; % 3rd folder in the hierarchy
options.MeasIndex=7;


%% VARIABLE CHECK

if nargin==0
    folderpath=pwd;
else
    folderpath=varargin{1};
end

if nargin>=2
    options=getOptions(options,varargin(1:end)); % CHECK IF NUMBER OF THE OPTION ARGUMENT OK!
end
input_options=options; % saving orginally passed options to output them in the original form for potential next use

%% PARSING AND VALIDATING THE PATH
voltage_paths_structure=struct;
if folderpath(end)==filesep
    folderpath(end)=[];
end
voltage_paths_structure.original=folderpath;
voltage_paths_structure.valid_structure=false; % status true if correct parsing of the folder
voltage_paths_structure.original_path_type='NOT RECOGNIZED!';
% voltage_paths_structure.ERROR_MESSAGE=''; % not appearing on default


if ~isfolder(folderpath)
    warning('This folder does not exist, just FYI')
end

parent_folders=strsplit(folderpath,filesep);

if isempty(parent_folders{end})
    parent_folders(end)=[]; % deleting last folder if just empty
end


if length(parent_folders)<length(options.FolderStructure)
    voltage_paths_structure.ERROR_MESSAGE='Not a valid folder structure, expected more parent folders. You are above measurement folder in a hierarchy.';
    warning(voltage_paths_structure.ERROR_MESSAGE);
    return
end

if length(parent_folders)>length(options.FolderStructure)
    voltage_paths_structure.ERROR_MESSAGE='Not a valid folder structure, expected less parent folders';
    warning(voltage_paths_structure.ERROR_MESSAGE);
    return
end


% populating folder structure
for ii=1:length(options.FolderStructure)
    voltage_paths_structure.(options.FolderStructure{ii})=parent_folders{ii};
end

% checking if the path is valid

% 1. checking the drive
if ~isvalidfolder(options.AllowedDrives,voltage_paths_structure.Drive(1))
    voltage_paths_structure.ERROR_MESSAGE='Not a valid drive.';
    warning(voltage_paths_structure.ERROR_MESSAGE);
    return
end


% 2. checking the date
if ~isvaliddate(voltage_paths_structure.(options.FolderStructure{options.DateIndex}))
    voltage_paths_structure.ERROR_MESSAGE='Not a valid date.';
    warning(voltage_paths_structure.ERROR_MESSAGE);
    return
end

% 3. checking the measurement formatting
if ~isvalidmeas(voltage_paths_structure.(options.FolderStructure{options.MeasIndex}))
    voltage_paths_structure.ERROR_MESSAGE='Not a measurement folder formatting';
    warning(voltage_paths_structure.ERROR_MESSAGE);
    return
end

% 4. checking the stage
if ~isvalidfolder(options.ProcessingStages,voltage_paths_structure.(options.FolderStructure{options.StageIndex}))
    voltage_paths_structure.ERROR_MESSAGE='Not a valid processing stage!';
    warning(voltage_paths_structure.ERROR_MESSAGE);
    return
end


%%%%%%%%%%%% Soft checks of the formating of stage and project, function
%%%%%%%%%%%% won't terminate but status will be false

% 5. checking the project
if ~isvalidfolder(options.AllowedProjectNames,voltage_paths_structure.(options.FolderStructure{options.ProjectIndex}))
    voltage_paths_structure.ERROR_MESSAGE='Not a valid project name!';
    warning(voltage_paths_structure.ERROR_MESSAGE);
else
    voltage_paths_structure.valid_structure=true;
end

%% GENERATING PATHS

% now if you get to this point, means that paths is valid and you can start
% creating output paths with one of the followint categories:
% options.OutputPathsTypes={'DCIMGOriginal','DCIMGTemporary',...
%     'PreprocessingTemporary','PreprocessingStorage','AnalysisTemporary','AnalysisStorage','ColdDCIMGStorage'};
% options.RecordingDrives={'D:\','E:\'}; % drives where you stream data directly from the cameras (dcimg files and raw metadata)
% options.AnalysisDrive='F:\'; % drive where you backup the data right after the recording
% options.ProcessedStorageDrive='G:\'; % drive where you permanently storred preprocessed and analysis data but not the raw, dcimg files
% options.ColdStorageDrives={'K:\','M:\'}; % cold storage drive in the priority order

% 1. DCIMGOriginal
for ii=1:length(options.RecordingDrives)
    voltage_paths_structure.([options.OutputPathsTypes{1},sprintf('%i',ii)])=replace_subfolder(folderpath,options.RecordingDrives{ii},1);
    voltage_paths_structure.([options.OutputPathsTypes{1},sprintf('%i',ii)])=...
        replace_subfolder(voltage_paths_structure.([options.OutputPathsTypes{1},sprintf('%i',ii)]),options.ProcessingStages{1},options.StageIndex);
    
    if strcmpi(voltage_paths_structure.([options.OutputPathsTypes{1},sprintf('%i',ii)]),folderpath)
        voltage_paths_structure.original_path_type=[options.OutputPathsTypes{1},sprintf('%i',ii)];
    end
end

% 2. DCIMGTemporary
tmpfolder=folderpath;
tmpfolder=replace_subfolder(tmpfolder,options.AnalysisDrive,1);
tmpfolder=replace_subfolder(tmpfolder,options.ProcessingStages{1},options.StageIndex);

voltage_paths_structure.(options.OutputPathsTypes{2})=tmpfolder;

if strcmpi(tmpfolder,folderpath)
    voltage_paths_structure.original_path_type=options.OutputPathsTypes{2};
end

% 3. PreprocessingTemporary
tmpfolder=folderpath;
tmpfolder=replace_subfolder(tmpfolder,options.AnalysisDrive,1);
tmpfolder=replace_subfolder(tmpfolder,options.ProcessingStages{2},options.StageIndex);

voltage_paths_structure.(options.OutputPathsTypes{3})=tmpfolder;

if strcmpi(tmpfolder,folderpath)
    voltage_paths_structure.original_path_type=options.OutputPathsTypes{3};
end

% 4. PreprocessingStorage
tmpfolder=folderpath;
tmpfolder=replace_subfolder(tmpfolder,options.ProcessedStorageDrive,1);
tmpfolder=replace_subfolder(tmpfolder,options.ProcessingStages{2},options.StageIndex);

voltage_paths_structure.(options.OutputPathsTypes{4})=tmpfolder;

if strcmpi(tmpfolder,folderpath)
    voltage_paths_structure.original_path_type=options.OutputPathsTypes{4};
end

% 5. AnalysisTemporary
tmpfolder=folderpath;
tmpfolder=replace_subfolder(tmpfolder,options.AnalysisDrive,1);
tmpfolder=replace_subfolder(tmpfolder,options.ProcessingStages{3},options.StageIndex);

voltage_paths_structure.(options.OutputPathsTypes{5})=tmpfolder;

if strcmpi(tmpfolder,folderpath)
    voltage_paths_structure.original_path_type=options.OutputPathsTypes{5};
end


% 6. AnalysisStorage
tmpfolder=folderpath;
tmpfolder=replace_subfolder(tmpfolder,options.ProcessedStorageDrive,1);
tmpfolder=replace_subfolder(tmpfolder,options.ProcessingStages{3},options.StageIndex);

voltage_paths_structure.(options.OutputPathsTypes{6})=tmpfolder;

if strcmpi(tmpfolder,folderpath)
    voltage_paths_structure.original_path_type=options.OutputPathsTypes{6};
end

% 7. ColdStorageDrives
for ii=1:length(options.ColdStorageDrives)
    tmpfolder=folderpath;
    tmpfolder=replace_subfolder(tmpfolder,options.ColdStorageDrives{ii},1);
    tmpfolder=replace_subfolder(tmpfolder,options.ProcessingStages{1},options.StageIndex);
    voltage_paths_structure.([options.OutputPathsTypes{7},sprintf('%i',ii)])=tmpfolder;
    if strcmpi(tmpfolder,folderpath)
        voltage_paths_structure.original_path_type=[options.OutputPathsTypes{7},sprintf('%i',ii)];
    end
end




%% CLOSING
t = datetime('now','TimeZone','local','Format','d-MMM-y HH:mm:ss');
options.AutomaticallyGeneratedBy='Radek Chrapkiewicz radekch@stanford.edu';
options.ExecutionTime=t;
options.input_options=input_options; % passing input options separately so they can be used later to feed back to function input.




end  %%% END VOLTPATHS FUNCTION



function valid=isvalidfolder(cellofvalidfoldernames,foldername)
% checking wherher a folder name belongs the allowed list
% RC
valid=(~isempty(find(cell2mat(strfind(cellofvalidfoldernames,foldername)))));
end

function [valid,measid]=isvalidmeas(measstring)
% RC
[measid,n,err]=sscanf(measstring,'meas%d');
if ~isempty(err) || n~=1 || measid<0
    valid=false;
    measid=[];
    return;
else
    valid=true;
end
end

function [valid,dateint]=isvaliddate(datestr)
% date should be 6 string as for example 20200519
% RC

[dateint,n,err]=sscanf(datestr,'%i');
if ~isempty(err) || n~=1 || dateint<0
    valid=false;
    dateint=[];
    return;
end

if dateint<20160000 || dateint>20300000 % wrong range
    valid=false;
elseif rem(dateint,1e4)>1231 || rem(dateint,1e4)<101 % wrong month
    valid=false;
elseif rem(dateint,1e2)>31 || rem(dateint,1e2)<1 % wrong day
    valid=false;
else
    valid=true;
end
end


function newfolderpath=replace_subfolder(folderpath,newsubfoldername,subfolder_appearence_index)
parentfolders=strsplit(folderpath,filesep);
parentfolders{subfolder_appearence_index}=newsubfoldername;
newfolderpath=fullfile(parentfolders{:});
end
