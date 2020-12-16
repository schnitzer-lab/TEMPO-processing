function [chunkSize,summary]=chunkh5(filepath,maxRAMfactor,varargin)
% HELP
% Determines the chunk size to load H5 without exceedint the maxRAMfactor limit e.g. 0.1 for 10% of remaining RAM.
% SYNTAX
%[chunksize,summary]= chunkh5(filepath,maxRAMfactor) - use 3, etc.
%[chunksize,summary]= chunkh5(filepath,maxRAMfactor,'optionName',optionValue,...) - passing options using a 'Name', 'Value' paradigm frequently used by Matlab native functions.
%[chunksize,summary]= chunkh5(filepath,maxRAMfactor,'options',options) - passing options as a structure.
%
% INPUTS:
% - filepath - ...
% - maxRAMfactor - ...
%
% OUTPUTS:
% - chunksize - ...
% - summary - %
% OPTIONS:
% - see below the section of code showing all possible input options and comments for their meaning. 

% HISTORY
% - 29-Jun-2020 21:41:54 - created by Radek Chrapkiewicz (radekch@stanford.edu)


%% OPTIONS
options=struct; % add your options below
options.dataset='/mov';

%% VARIABLE CHECK 

if nargin>=3
options=getOptions(options,varargin(1:end)); % CHECK IF NUMBER OF THE OPTION ARGUMENT OK!
end
summary=initSummary(options);


%% CORE
%The core of the function should just go here.
[msize,summarymov]=h5moviesize(filepath);

summary.movie_size=msize;
summary.availableRAM=checkRAM;
summary.frame_MB=double(msize(1)*msize(2)*summarymov.bytes_per_px)/2^20;
chunkSize=round(maxRAMfactor*summary.availableRAM/summary.frame_MB/2^20);
summary.chunkSize=chunkSize;
%% CLOSING
summary.input_options=input_options; % passing input options separately so they can be used later to feed back to function input.
summary.execution_duration=toc(summary.execution_duration);


end  %%% END CHUNKH5
