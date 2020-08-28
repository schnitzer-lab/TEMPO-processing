function [chunksFirstLast,summary]=chunkFrames(chunkSize,frameFirstLast)
% Prepare ranges of frames to load from a files - chunks to load without overfilling the memory.
% SYNTAX
% [chunksFirstLast,summary]= chunkFrames(chunkSize,frameFirstLast)
%
% INPUTS:
% - chunkSize - an interger e.g. 500 if that's reasonable to load into
% memory
% - frameFirstLast - vector, two elements, e.g. [100,1000] if you want to
% load from 100th to 1000th frames
%
% OUTPUTS:
% - chunksFirstLast - array
% - summary - basic description informing about function execution.
% 
% HISTORY
% - 2019-02 - originally created for MicroscopesRecordings  by Radek Chrapkiewicz (radekch@stanford.edu)
% - 2020-06-01 20:27:22 - adapted for VoltageIMagingAnalsysi by RC
%
% EXAMPLE:
% chunkFrames(100,[5,320])
%      5   104
%    105   204
%    205   304
%    305   320
% 
% DEMO AND UNITTEST (must run if any changes are introduced!)
% runtests('test_chunkFrames')
%
% ISSUES
% #1
%
% TODO
% *1

%% Summary preparation
summary.function_path=mfilename('fullpath');
summary.execution_started=datetime('now');
summary.execution_duration=tic;

%% variable check
if frameFirstLast(2)<frameFirstLast(1)
    error('last frame cannot be smaller than first one')
end

if chunkSize<1
    error('Chunk cannot be smaller than 1 frame')
end

if rem(chunkSize,1)~=0
    error('Chunk cannot be fractional')
end

%% CORE
%The core of the function should just go here.

chunksFirstLast=[];
nframes2load=frameFirstLast(2)-frameFirstLast(1)+1;
if chunkSize>=nframes2load
    chunksFirstLast=frameFirstLast;
else
    block_idx=0;
    lastframe=frameFirstLast(1)-1;
    %     while (lastframe+1<nframes2load)&&(lastframe+1<frameFirstLast(2))
    while lastframe+1<=frameFirstLast(2)
        block_idx=block_idx+1;
        firstframe=max(lastframe+1,frameFirstLast(1));
        lastframe=min(frameFirstLast(1)+block_idx*chunkSize-1,frameFirstLast(2));
        if lastframe<frameFirstLast(2)
            chunksFirstLast(end+1,:)=[firstframe,lastframe];
        else
            chunksFirstLast(end+1,:)=[firstframe,frameFirstLast(2)];
        end
    end
end


%% CLOSING
summary.author='Radek Chrapkiewicz (radekch@stanford.edu)';
summary.input_options=[]; %  no options for this function
summary.execution_duration=toc(summary.execution_duration);
summary.description='Prepared for the VoltageImagingAnalysis package';


end  %%% END CHUNKFRAMES


