function [fps,nDroppedFrames,summary]=calcTimestamps(timestamps,varargin)
% Reading out and analyzing time stamps from the DCIMG file to gate frame rate and dropped frames.
% higher level function with dependencies using '*Timestamps' functions.
% SYNTAX
%[timestampsfpsnDroppedFrames,summary]= getTimestamps(timestamps)
%[timestampsfpsnDroppedFrames,summary]= getTimestamps(timestamps,'optionName',optionValue,...) - passing options using a 'Name', 'Value' paradigm frequently used by Matlab native functions.
%[timestampsfpsnDroppedFrames,summary]= getTimestamps(timestampsS,'options',options) - passing options as a structure.
%
% INPUTS:
% - dcimgFilePath - path to your dcimg file
%
% OUTPUTS:
% - timestamps - vector of time stamps for consecutive frames in seconds
% - fps - median frame rate from the regording
% - nDroppedFrames - number of dropped frames
% - summary - structure containing extra function outputs, diagnostic of execution, performance
% as well as the internal configuration of the function that includes all input options
%
% OPTIONS:
% - see below the section of code showing all possible input options and comments for their meaning.

% HISTORY
% - 20-06-03 12:16:05 - created by Radek Chrapkiewicz (radekch@stanford.edu)
% - 2020-08-31 13:02:36 -  removed embedded functions into separate ones,
% to have independent import and generation processes, also changed name
% from 'getTimestamps' -> 'calcTimestamps'


%% OPTIONS

options.plot=false;


%% VARIABLE CHECK

if nargin>=2
    options=getOptions(options,varargin(1:end)); % CHECK IF NUMBER OF THE OPTION ARGUMENT OK!
end
input_options=options; % saving orginally passed options to output them in the original form for potential next use

%% Summary preparation
summary=initSummary;
summary.input_options=input_options; 

%% CORE
%The core of the function should just go here.
disps('Calculating time stamps');

% summary.dcimgFilePath=dcimgFilePath;


summary.timestamps=timestamps;

summary.interval=diff(timestamps);

summary.fpsVec= 1./summary.interval;
summary.medianFps=median(summary.fpsVec);
fps=summary.medianFps;

summary.jitter=std(summary.interval);
summary.medianInterval=median(summary.interval);
summary.intervalDeviations=abs(summary.interval-summary.medianInterval);
summary.framesDroppedVec=round(summary.intervalDeviations./summary.medianInterval);
summary.nDroppedFramesFrames=sum(summary.framesDroppedVec);
nDroppedFrames=summary.nDroppedFramesFrames;


if options.plot
    plotTimestamps(timestamps,summary)
end


%% CLOSING

summary=closeSummary(summary);


end  %%% END GETTIMESTAMPS



