function [summary]=closeSummary()
%
% HELP
% Standard initialization of the summary within a function.
% SYNTAX
%[summary]= initSummary() - use 1 if no arguments are allowed
% - summary - %
% OPTIONS:
% - see below the section of code showing all possible input options and comments for their meaning. 

% HISTORY
% - 13-Sep-2020 20:04:52 - created by Radek Chrapkiewicz (radekch@stanford.edu)


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




end  %%% END INITSUMMARY
