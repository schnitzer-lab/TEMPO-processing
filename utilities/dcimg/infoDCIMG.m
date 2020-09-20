function [info]=infoDCIMG(filePath)
% HELP
% Basic info about the content of the DCIMG file after loading the first frame.
% SYNTAX
%[info]= getDcimgInfo(filePath)

% HISTORY
% - 13-Sep-2020 17:12:00 - created by Radek Chrapkiewicz (radekch@stanford.edu)

options.transpose=true;
% loading first frame

if ~isfile(filePath)
    error('That is not even a file!')
end

[firstFrame,framesNumber]=  dcimgmatlab(int32(0), filePath); % that's the mex file that should be on a path
loadingTimeFrame=toc;

if options.transpose
    firstFrame=firstFrame'; % this transposition is to make it compatible with imshow, but flips camera rows with columns
    % adding to info file size information
end

% adding frame info to the info at this point 

frameInfo=whos('firstFrame');
fileInfo=dir(filePath);
info.path=filePath;
info.type=frameInfo.class;

info.framesNumber=double(framesNumber);
info.frameSize=size(firstFrame);


info.frameMB=frameInfo.bytes/2^20;
info.fileSizeGB=fileInfo.bytes/2^30;
info.date=fileInfo.date;

info.bitDepth=round(8*fileInfo.bytes/(prod(info.frameSize)*info.framesNumber));
info.loadingTimeFrame=loadingTimeFrame;





end  %%% END GETDCIMGINFO
