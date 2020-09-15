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
% - fps - median frame rate from the regording
% - nDroppedFrames - number of dropped frames
% - summary:
%   - timestamps - vector of time stamps for consecutive frames in seconds
%
% OPTIONS:
% - plot

% HISTORY
% - 2020-06-03 12:16:05 - created by Radek Chrapkiewicz (radekch@stanford.edu)
% - 2020-08-31 13:02:36 -  removed embedded functions into separate ones,
% to have independent import and generation processes, also changed name
% from 'getTimestamps' -> 'calcTimestamps'
% - 2020-09-15 10:01:54 - shortened and improved naming RC


%% Options
options.plot=false;

%% Variable check
if nargin>=2, options=getOptions(options,varargin(1:end)); end
summary=initSummary;
summary.inputOptions=options; 

%% Core
disps('Calculating time stamps');

summary.medianFps=[]; % init field
summary.nDroppedFrames=[]; % init field
summary.timestamps=timestamps;
summary.interval=diff(timestamps);
summary.fpsVec= 1./summary.interval;
summary.medianFps=median(summary.fpsVec);
fps=summary.medianFps;
summary.jitter=std(summary.interval);
summary.medianInterval=median(summary.interval);
summary.intervalDeviations=abs(summary.interval-summary.medianInterval);
summary.framesDroppedVec=round(summary.intervalDeviations./summary.medianInterval);
summary.nDroppedFrames=sum(summary.framesDroppedVec);
nDroppedFrames=summary.nDroppedFrames;

if options.plot
    plotTimestamps(timestamps,summary)
end

summary=closeSummary(summary);
end  %%% END GETTIMESTAMPS





