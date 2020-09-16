function [metadata]=importLvMetaData(lvSettingsFolder,varargin)
% [metadata]=importLvMetaData(lvSettinsPath)
% [metadata]=importLvMetaData(lvSettinsPath,'parameter',value,...)

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
% - 2020-09-15 16:44:48 - minimalistic - reading basic info fps, binning,
% depth. If anything else we will add it


%% OPTIONS

% [options]=MetadataStructure(); removed by % - 2020-09-15 16:50:04 -   RC

options.LVSettingsFile='allsettings.txt';
options.autoCropping=true;
options.savePath=[];
options.verbose=true;
options.plot=true;
options.guessBandPassFilter=true;

% Variable check

if nargin>=2
    options=getOptions(options,varargin);
end

% Core 
metadata=struct;

% Detect Sampling Rate
try
    A=fileread(fullfile(lvSettingsFolder,options.LVSettingsFile)); B=strfind(A, 'Actual frame rate');
    metadata.fpsLV=floor(str2double(A(B+153:B+157))); % in Hz
    fprintf('Frame Rate: %1.0f Hz \n', metadata.fpsLV);
catch
    warning('Cannot detect sampling rate');
end

% Detect Hardware Binning
try
    A=fileread(fullfile(lvSettingsFolder,options.LVSettingsFile)); B=strfind(A, 'Binning (px)');
    metadata.hardwareBinning=str2double(A(B+26:B+26));
    fprintf('Hardware Binning: %1.0f \n',metadata.hardwareBinning);
catch
    warning('Cannot detect Hardware Binning');
end

% Detect depth of imaging RC added
try
    strpattern='Depth (um)</Name>';
    A=fileread(fullfile(lvSettingsFolder,options.LVSettingsFile)); B=strfind(A, strpattern);
    metadata.depth=str2double(A(B+length(strpattern)+7:B+length(strpattern)+13));
    fprintf('Depth: %1.0f %sm \n',metadata.depth,char(181));
catch
    warning('Cannot detect depth of imaging');
end


disps('Metadata succesfully loaded')

    function disps(string)
        FUNCTION_NAME='importLvMetaData';
        if options.verbose
            fprintf('%s %s: %s\n', datetime('now'),FUNCTION_NAME,string);
        end
    end
end



