function [info]=infoDCIMG(filePath)
% HELP
% Basic info about the content of the DCIMG file after loading the first frame.
% SYNTAX
%[info]= getDcimgInfo(filePath)

% HISTORY
% - 13-Sep-2020 17:12:00 - created by Radek Chrapkiewicz (radekch@stanford.edu)
% - 2021-04-14 03:18:37 -  getting frame info right after loading through MEX RC

options.transpose=true;
% loading first frame

if ~isfile(filePath)
    error('That is not even a file!')
end
tic
[firstFrame,framesNumber]=  dcimgmatlab(int32(0), filePath); % that's the mex file that should be on a path
frameInfo=whos('firstFrame');
dcimgInfo=importDcimgHeader(filePath); % % - 2020-11-10 17:32:01 -   RC
framesNumberHeader=dcimgInfo.totalFrames;
if framesNumber~=framesNumberHeader
    warning('Actual number of frames in the DCIMG file is different than reportded by "dcimgmatlab". Taking value from the binary file readout');
    if framesNumberHeader~=0
        framesNumber=framesNumberHeader;
    else
        warning('Actually, the number of frames from the header is just 0, so taking it back - we get number of frames from MEX');
    end
end 
loadingTimeFrame=toc;

if options.transpose
    firstFrame=firstFrame'; % this transposition is to make it compatible with imshow, but flips camera rows with columns
    % adding to info file size information
end

% adding frame info to the info at this point 


fileInfo=dir(filePath);
info.path=filePath;
info.type=frameInfo.class;

info.framesNumber=double(framesNumber);
info.frameSize=size(firstFrame);


info.frameMB=frameInfo.bytes/2^20;
info.fileSizeGB=fileInfo.bytes/2^30;
info.date=fileInfo.date;


info.bitDepth=frameInfo.bytes/prod(frameInfo.size)*8;


% round(8*fileInfo.bytes/(prod(info.frameSize)*info.framesNumber));
info.loadingTimeFrame=loadingTimeFrame;





end  %%% END GETDCIMGINFO
