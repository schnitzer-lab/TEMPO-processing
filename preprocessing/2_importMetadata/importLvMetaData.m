function [metadata]=importLvMetaData(lvSettinsPath,varargin)
% [metadata]=importLvMetaData(lvSettinsPath)
% [metadata]=importLvMetaData(lvSettinsPath,'parameter',value,...)
%
%
% HISTORY
% - by SH 2020
% - adopted for preprocessing by RC 06/23/2020
% - 2020-08-28 20:13:53 - trimmed to import just LV settings RC
%
% RC changes:
% - don't change the working directory with cd, it messes up the
% availability of the functions/ script on the path
% - options parsing added
% - simplified and logically restricted to the content of the raw meta data
% without conflating with processing.
% - added depth detection


%% OPTIONS

[options]=MetadataStructure();

options.LVSettingsFile='allsettings.txt';
options.autoCropping=true;
options.savePath=[];
options.verbose=true;
options.plot=true;
options.guessBandPassFilter=true;

%% VARIABLE CHECK

if nargin>=2
    options=getOptions(options,varargin);
end


%% CORE

metadata=options;
metadata.dataPath=allPaths.dcimgPath;
metadata.totalBinning=metadata.softwareBinning*metadata.hardwareBinning;

% Find Green & Red DCIMG files
filename=dir(fullfile(allPaths.dcimgPath,'*.dcimg')); % G always comes before R
% By default, Voltage is in Green Channel.
[green, red]=filename.name;
if ~strcmpi(metadata.voltageChannel,'green')
    metadata.voltageChannel='Red'; % default for AcemNeon
    metadata.referenceChannel='Green'; % default for mRuby3
    [red, green]=filename.name;
end
metadata.voltageFileName=green;
metadata.referenceFileName=red;


% Detect Sampling Rate
try
    A=fileread(fullfile(allPaths.dcimgPath,options.LVSettingsFile)); B=strfind(A, 'Actual frame rate');
    metadata.fps=floor(str2double(A(B+153:B+157))); % in Hz
    fprintf('Frame Rate: %1.0f Hz \n', metadata.fps);
catch
    warning('Cannot detect sampling rate');
end

% Detect Hardware Binning
try
    A=fileread(fullfile(allPaths.dcimgPath,options.LVSettingsFile)); B=strfind(A, 'Binning (px)');
    metadata.hardwareBinning=str2double(A(B+26:B+26));
    fprintf('Hardware Binning: %1.0f \n',metadata.hardwareBinning);
catch
    warning('Cannot detect Hardware Binning');
end

% Detect depth of imaging RC added
try
    strpattern='Depth (um)</Name>';
    A=fileread(fullfile(allPaths.dcimgPath,options.LVSettingsFile)); B=strfind(A, strpattern);
    metadata.depth=str2double(A(B+length(strpattern)+7:B+length(strpattern)+13));
    fprintf('Depth: %1.0f %sm \n',metadata.depth,char(181));
catch
    warning('Cannot detect depth of imaging');
end

% Load TTL file if needed
if metadata.loadTTL
    try
        Nametemp=dir('*_framestamps 0.txt');
        [TTL]=importdata(Nametemp.name);
        metadata.TTL=TTL(metadata.FramesRequested,4);
    catch
        warning('Cannot detect TTL file');
    end
end

disps('Metadata succesfully loaded')

    function disps(string) %overloading disp for this function - this function should be nested
        %         temp=mfilename('fullpath');
        %         [~,FUNCTION_NAME,~]=fileparts(temp);
        FUNCTION_NAME='getRawMetaData';
        if options.verbose
            fprintf('%s %s: %s\n', datetime('now'),FUNCTION_NAME,string);
        end
    end
end

function [metadata]=MetadataStructure()

% Channels Settings
metadata.dataPath=[];
metadata.voltageChannel='Green'; % default for AcemNeon
metadata.referenceChannel='Red'; % default for mRuby3
metadata.voltageFileName=[];
metadata.referenceFileName=[];

% Acquisition Settings
metadata.fps=[]; % in Hz
metadata.frameDimension=[]; % in pixel
metadata.totalFrames=[];
metadata.dimension=[];
metadata.depth=[];
metadata.hardwareBinning=1; %usually

% Loading Settings
metadata.softwareBinning=8; % by default
metadata.totalBinning=[];
metadata.autoCropping=true;
metadata.ROI=[]; % for autocroping; DCIMG and Matlab XY convention inverted
metadata.vectorBandPassFilter=[];% to estime best filer for reg & moco

% TTL for behavior sync
metadata.loadTTL=false;
metadata.TTL=[];

% % Chunking option, all auto-determined
% metadata.Chunking=false; % no chunking by default
% metadata.ChunksNumber=[];
% metadata.ChunksVector=[];
% metadata.LoadedFramesperChunk=[]; % full or chunk window
% metadata.DimensionLoadedperChunk=[];
%
% % Memory Settings
% metadata.memoryAvailable=[];
% metadata.FileSizeRaw=[];
% metadata.FileSizeLoaded=[];
% metadata.FileSizeLoadedperChunk=[];
% metadata.FileSizeProcessed=[];

% % Export settings
% metadata.dcimgPath=[];
% metadata.h5Path=[];
% metadata.diagnosticLoading=[];
% metadata.diagnosticRegistration=[];
% metadata.diagnosticMotionCorr=[];
% metadata.diagnosticUnmixing=[];
end


