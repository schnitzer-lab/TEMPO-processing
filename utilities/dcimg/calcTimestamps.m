function [timestamps,fps,ndropped,summary]=calcTimestamps(dcimgFilePath,varargin)
% Reading out and analyzing time stamps from the DCIMG file to gate frame rate and dropped frames.
% higher level function with dependencies using '*Timestamps' functions.
% SYNTAX
%[timestampsfpsndropped,summary]= getTimestamps(dcimgFilePath)
%[timestampsfpsndropped,summary]= getTimestamps(dcimgFilePath,'optionName',optionValue,...) - passing options using a 'Name', 'Value' paradigm frequently used by Matlab native functions.
%[timestampsfpsndropped,summary]= getTimestamps(dcimgFilePath,'options',options) - passing options as a structure.
%
% INPUTS:
% - dcimgFilePath - path to your dcimg file
%
% OUTPUTS:
% - timestamps - vector of time stamps for consecutive frames in seconds
% - fps - median frame rate from the regording
% - ndropped - number of dropped frames
% - summary - structure containing extra function outputs, diagnostic of execution, performance
% as well as the internal configuration of the function that includes all input options
%
% OPTIONS:
% - see below the section of code showing all possible input options and comments for their meaning.

% HISTORY
% - 20-06-03 12:16:05 - created by Radek Chrapkiewicz (radekch@stanford.edu)
% - 2020-08-31 13:02:36 -  removed embedded functions into separate ones,
% to have independent import and generation processes, also changed name
% from 'getTimestamps' -> 'calcTimestamps'


%% OPTIONS

options.plot=false;
options.reader_filename='dct_readtimestamps.exe';
options.reader_folderpath=fileparts(mfilename('fullpath'));


%% VARIABLE CHECK

if nargin>=2
    options=getOptions(options,varargin(1:end)); % CHECK IF NUMBER OF THE OPTION ARGUMENT OK!
end
input_options=options; % saving orginally passed options to output them in the original form for potential next use

%% Summary preparation
summary.function_path=mfilename('fullpath');
summary.execution_started=datetime('now');
summary.execution_duration=tic;

%% CORE
%The core of the function should just go here.
disps('Calculating time stamps');

summary.dcimgFilePath=dcimgFilePath;

timestamp_filepath=genTimestamps(dcimgFilePath,options.reader_filename,options.reader_folderpath);    
timestamps=importTimestamps (timestamp_filepath);
summary.timestamps=timestamps;

summary.interval=diff(timestamps);

summary.fpsvec= 1./summary.interval;
summary.median_fps=median(summary.fpsvec);
fps=summary.median_fps;

summary.jitter=std(summary.interval);
summary.median_interval=median(summary.interval);
summary.interval_deviations=abs(summary.interval-summary.median_interval);
summary.frames_dropped_vec=round(summary.interval_deviations./summary.median_interval);
summary.frames_dropped_n=sum(summary.frames_dropped_vec);
ndropped=summary.frames_dropped_n;

if options.plot
    plotTimestamps(timestamps,summary)
end


%% CLOSING
summary.input_options=input_options; % passing input options separately so they can be used later to feed back to function input.
summary.execution_duration=toc(summary.execution_duration);
summary.contact='Radek Chrapkiewicz (radekch@stanford.edu)';


end  %%% END GETTIMESTAMPS



