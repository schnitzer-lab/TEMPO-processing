function [summary]=initSummary(varargin)
% HELP
% Standard initialization of the summary within a function.
% SYNTAX
%[summary]= initSummary()
%[summary]= initSummary(inputOptions) 
% - summary - %
% OPTIONS:
% - see below the section of code showing all possible input options and comments for their meaning. 

% HISTORY
% - 13-Sep-2020 20:04:52 - created by Radek Chrapkiewicz (radekch@stanford.edu)
% - 2020-09-21 01:00:37 - you can pass input options to shorten function RC


%% Summary preparation


functionNames=dbstack;
if length(functionNames)>=2 
    callingFunction=functionNames(2).name;
else
    callingFunction='';
end

summary.function=callingFunction;
summary.executionStarted=datetime('now');
summary.executionDuration=tic;

if nargin>=1
    summary.inputOptions=varargin{1};
end



end  %%% END INITSUMMARY
