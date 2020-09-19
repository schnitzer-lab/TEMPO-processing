function [fps,nDroppedFrames,summary]=getFps(filePath)
% HELP
% Higher level function, importing and analyzing dcimg time stamps
% (generating if missing) and pulling out fps and warning
% if any frames were dropped.
% SYNTAX
%[fpsnDroppedFrames,summary]= getFps(filePath)
%
% INPUTS:
% - filePath - file path to dcimg or time stamps file
%
% OUTPUTS:
% - fps - median frame acquisition rate in Hz
% - nDroppedFrames - number of dropped frames
% - summary - extra outputs from the time stamps calculatins like jitter 

% HISTORY
% - 13-Sep-2020 20:35:40 - created by Radek Chrapkiewicz (radekch@stanford.edu)

summary=initSummary;

switch getExt(filePath)
    case '.txt'
        timeStampPath=filePath;
    case '.dcimg'
        timeStampPath=[filePath,'.txt'];
    otherwise 
        error('Unsupported %s format of the file',getExt(filePath));
end

if ~isfile(timeStampPath)
    disps('Time stamps not generated before, generating')
    dcimgFilePath=findDCIMG(filePath);
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
