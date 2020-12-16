function [timeTrace,summary]=mask2trace(movie,mask,varargin)
% HELP MASK2TRACE.M
% Masking movie and creating a corresponding time trace from the summed pixels within a mask.
% SYNTAX
%[timeTrace,summary]= mask2trace(movie,mask) - use 3, etc.
%[timeTrace,summary]= mask2trace(movie,mask,'optionName',optionValue,...) - passing options using a 'Name', 'Value' paradigm frequently used by Matlab native functions.
%[timeTrace,summary]= mask2trace(movie,mask,'options',options) - passing options as a structure.
%
% INPUTS:
% - movie - ...
% - mask - ...
%
% OUTPUTS:
% - timeTrace - ...
% - summary - %
% OPTIONS:
% - see below the section of code showing all possible input options and comments for their meaning. 

%
% HISTORY
% - 15-Dec-2020 17:20:18 - created by Radek Chrapkiewicz (radekch@stanford.edu)

%% OPTIONS (type 'help getOptions' for details)
options=struct; % add your options below 
options.plot

%% VARIABLE CHECK 
if nargin>=2
options=getOptions(options,varargin(1:end)); % CHECK IF NUMBER OF THE OPTION ARGUMENT OK!
end
summary=initSummary(options);


%% CORE
%The core of the function should just go here.

mask=cast(mask,class(movie));

maskedMovie=mask.*movie;
timeTrace=sum(maskedMovie,[1,2]);
timeTrace=squeeze(timeTrace);

if options.plot
    plot(timeTrace)
    xlabel('Frames (#)')
end 
formatPlot;


%% CLOSING
summary=closeSummary(summary);
end  %%% END MASK2TRACE


%%% Automatically generated using 'genMFile' function (by Radek Chrapkiewicz) with the following configuration:
% summary=
%              function: 'genMFile'
%     executionStarted: 15-Dec-2020 17:19:39
%    executionDuration: 39.4142
%             computer: 'BFM'
%                 user: 'Radek'
%        input_options: [1×1 struct]
%              contact: 'Radek Chrapkiewicz (radekch@stanford.edu)'
%
%