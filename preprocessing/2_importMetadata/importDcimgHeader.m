function [dcimgInfo,summary]=importDcimgHeader(dcimgPath,varargin)
%
% HELP
% Getting information about the movie from the raw DCIMG header
% SYNTAX
%[output_arg1,summary]= importDcimgHeader(dcimgPath) - use 2, etc.
%[output_arg1,summary]= importDcimgHeader(dcimgPath,'optionName',optionValue,...) - passing options using a 'Name', 'Value' paradigm frequently used by Matlab native functions.
%[output_arg1,summary]= importDcimgHeader(dcimgPath,'options',options) - passing options as a structure.

% HISTORY
% core taken from original Simon metadata parsing function.
% - 28-Aug-2020 20:18:01 - created by Radek Chrapkiewicz (radekch@stanford.edu)
%
% ISSUES
% #1 - issue 1
%
% TODO
% *1 - get the first working version of the function!


%% OPTIONS (Biafra style, type 'help getOptions' for details) or: https://github.com/schnitzer-lab/VoltageImagingAnalysis/wiki/'options':-structure-with-function-configuration
options=struct; % add your options below 

%% VARIABLE CHECK
if nargin>=2
options=getOptions(options,varargin(1:end)); % CHECK IF NUMBER OF THE OPTION ARGUMENT OK!
end
input_options=options; % saving orginally passed options to output them in the original form for potential next use

%% PATHS

%% Summary preparation
summary.function_path=mfilename('fullpath');
summary.execution_started=datetime('now');
summary.execution_duration=tic;


%% CORE


% Read just the 32-bit header information

fid = fopen(dcimgPath,'rb');
dcimgMeta = fread(fid,202,'uint32=>uint32');
fclose(fid);
width = double(dcimgMeta(147)); % index 47: x dim
height = double(dcimgMeta(148)); % index 48: y dim
nFrame = double(dcimgMeta(144)); % index 44: number of frames

dcimgInfo.frameDimension=[width height]; % in pixel
dcimgInfo.totalFrames=nFrame;
dcimgInfo.dimension=[dcimgInfo.frameDimension dcimgInfo.totalFrames];
fprintf('Movie Dimension: %1.0f x %1.0f x %1.0f pixels \n', dcimgInfo.dimension);


%% CLOSING
summary.input_options=input_options; % passing input options separately so they can be used later to feed back to function input.
summary.execution_duration=toc(summary.execution_duration);


end  %%% END IMPORTDCIMGHEADER
