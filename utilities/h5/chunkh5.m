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
%
% HISTORY
% - 29-Jun-2020 21:41:54 - created by Radek Chrapkiewicz (radekch@stanford.edu)
%
% ISSUES
% #1 - issue 1
%
% TODO
% *1 - get the first working version of the function!

%% OPTIONS (Biafra style, type 'help getOptions' for details) or: https://github.com/schnitzer-lab/VoltageImagingAnalysis/wiki/'options':-structure-with-function-configuration
options=struct; % add your options below
options.dataset='/mov';

%% VARIABLE CHECK 

if nargin>=3
options=getOptions(options,varargin(1:end)); % CHECK IF NUMBER OF THE OPTION ARGUMENT OK!
end
input_options=options; % saving orginally passed options to output them in the original form for potential next use


%% Summary preparation
summary.function_path=mfilename('fullpath');
summary.execution_started=datetime('now');
summary.execution_duration=tic;


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
