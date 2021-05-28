function disps(string,varargin)
% HELP
% Display of a string with a name of the calling function and current date. 
% SYNTAX
% disps(string) - just one input argument, no output arguments.
% disps(string,parameter1,parameter2) - using sprintf syntax
%
% INPUTS:
% - string - string to be displayed.
%
% EXAMPLE:
% disps('%i/%i=%.1f',5,2,5/2)          
% >> 22-May-2021 15:34:02 : 5/2=2.5

% HISTORY
% - 31-Aug-2020 10:22:46 - created by Radek Chrapkiewicz (radekch@stanford.edu)
% - 2021-05-22 15:26:53 - providing srpintf syntax  RC


functionNames=dbstack;
if length(functionNames)>=2 
    callingFunction=functionNames(2).name;
else
    callingFunction='';
end
callingFunction=(callingFunction);

if nargin>=2
    string=sprintf(string,varargin{:});
end

fprintf('%s %s: %s\n', datetime('now'),callingFunction,string);

end