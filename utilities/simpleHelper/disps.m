function disps(string)
% HELP
% Display of a string with a name of the calling function and current date. 
% SYNTAX
% disps(string) - just one input argument, no output arguments.
%
% INPUTS:
% - string - string to be displayed.

% HISTORY
% - 31-Aug-2020 10:22:46 - created by Radek Chrapkiewicz (radekch@stanford.edu)

functionNames=dbstack;
if length(functionNames)>=2 
    callingFunction=functionNames(2).name;
else
    callingFunction='';
end
callingFunction=(callingFunction);
fprintf('%s %s: %s\n', datetime('now'),callingFunction,string);
end