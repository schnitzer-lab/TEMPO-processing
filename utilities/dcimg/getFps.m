function [fps,nDroppedFrames,summary]=getFps(dcimgFilePath,varargin)
% HELP
% Higher level function, importing and analyzing dcimg time stamps
% (generating if missing) and pulling out fps and warning
% if any frames were dropped.
% SYNTAX
%[fpsnDroppedFrames,summary]= getFps(dcimgFilePath)
%
% INPUTS:
% - dcimgFilePath - ...
%
% OUTPUTS:
% - fps - ...
% - nDroppedFrames - ...
% - summary - %

% HISTORY
% - 13-Sep-2020 20:35:40 - created by Radek Chrapkiewicz (radekch@stanford.edu)



summary=initSummary;

timeStampPath=[dcimgFilePath,'.txt'];
if ~isfile(dcimgFilePath)
    disps('Time stamps not generated before, generating')
    genTimesamps(dcimgFilePath);
end
summary.timeStampPath=timeStampPath;

timestamps=importTimestamps(timeStampPath);
summary.timestamps=timestamps;
[fps,nDroppedFrames,summaryCalc]=calcTimestamps(timestamps);

if nDroppedFrames>0
    error('Frames dropped in this recording');
end

summary=mergeSummary(summary,summaryCalc);

end  %%% END GETFPS
