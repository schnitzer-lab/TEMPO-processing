function [fps,nDroppedFrames,summary]=getFps(filePath,varargin)
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
% - 2021-03-23 09:35:38 - added option to return warnings instead of errors if frame dropping occurs  RC

options=struct;
options.dropError=true; % returning error if frame dropping occured


if nargin>=2
    options=getOptions(options,varargin);
end
summary=initSummary(options);

switch getExt(filePath)
    case '.txt'
        timeStampPath=filePath;
    case '.dcimg'
        timeStampPath=[filePath,'.txt'];
    case '.h5'
        folderPath=fileparts(filePath);
        folderPathMeta=fullfile(folderPath,'LVMeta');
        fList=rdir(fullfile(folderPathMeta,'*-cG.dcimg.txt'));
        if isempty(fList)
            timeStampPath=[];
            warning('No time stamp file');
            fps=parseFps(filePath);
            nDroppedFrames=[];
            return
        else
            timeStampPath=fList(1).name;
        end            
    otherwise 
        error('Unsupported %s format of the file',getExt(filePath));
end

if ~isfile(timeStampPath)
    disps('Time stamps not generated before, generating')
    dcimgFilePath=findDCIMG(filePath);
    try
        genTimestamps(dcimgFilePath);
    catch ME1
        warning('Cannot generate time stamps, parsing fps from the filename and terminating')
        [~,endIndex] = regexp(dcimgFilePath,'-fps');
        fps=sscanf(dcimgFilePath((endIndex+1):end),'%f');
        nDroppedFrames=-1;
        summary.error=ME1;
        summary=closeSummary(summary);
        return;       
    end
end
summary.timeStampPath=timeStampPath;

timestamps=importTimestamps(timeStampPath);
summary.timestamps=timestamps;
[fps,nDroppedFrames,summaryCalc]=calcTimestamps(timestamps);

if nDroppedFrames>0
    if options.dropError
        error('Frames dropped in this recording');
    else
        warning('Frames dropped in this recording');
    end
    
end

summary=mergeSummary(summary,summaryCalc);

end  %%% END GETFPS
