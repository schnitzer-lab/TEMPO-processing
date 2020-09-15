function [frame1frameLast]=parseFrameRange(frameRange,totalNumFrames)
% HELP PARSEframeRange.M
% Universal parser of the number of frames to load applying a following convention.
% 1) If frameRange=[] or Inf, then [1,lastFrame];
% 2) frameRange=iFrame, then [1,iFrame];
% 3) frameRange=[iFrame,jFrame] then [iFrame,min(jFrame,totalNumFrames)]
% iFrame and jFrame can be Inf, for last frame
% SYNTAX
%[frame1frameLast,summary]= parseframeRange(frameRange,totalNumFrames)\
%
% INPUTS:
% - frameRange - scalar or 2 elements vector of integers
% - totalNumFrames - scaler integer
%
% OUTPUTS:
% - frame1frameLast - vector of two integers [1stframe,lastFrame]

% HISTORY
% - 15-Sep-2020 01:42:17 - created by Radek Chrapkiewicz (radekch@stanford.edu)


if isempty(frameRange)
    frame1frameLast=[1,totalNumFrames];
elseif length(frameRange)==1
    if isinf(frameRange)
        frame1frameLast=[1,totalNumFrames]; % read last frame
    else
        frame1frameLast=[1,frameRange];
    end
elseif length(frameRange)==2
    frame1frameLast=frameRange;
    if frame1frameLast(1)==Inf
        frame1frameLast(1)=totalNumFrames;
    elseif frame1frameLast(1)>totalNumFrames
        warning('Specified a frame outside the range')
        frame1frameLast(1)=totalNumFrames;
    end
    if frame1frameLast(2)==Inf
        frame1frameLast(2)=totalNumFrames;
    elseif frame1frameLast(2)>totalNumFrames
        warning('Specified a frame outside the range')
        frame1frameLast(2)=totalNumFrames;
    end
    if frame1frameLast(1)<1
        warning('First frame should not be smaller than one, fixing this')
        frame1frameLast=1;
    end
else
    error('Expected to get scalar or 2-elements vectors of integers');
end

if rem(sum(frame1frameLast),1)~=0
    error('Frame range must be integer');
end

end  %%% END PARSEframeRange

