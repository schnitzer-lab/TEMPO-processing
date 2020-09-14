function [summaryOut]=closeSummary(summaryIn,varargin)
%
% HELP
% Standard initialization of the summary within a function.
% SYNTAX
% [summaryOut]=closeSummary(summaryIn)
% [summaryOut]=closeSummary(summaryIn,contact)
%
% summaryIn - summary generated in another function, must have
% 'executionDuration' field
% contact - contact info for the function author, for debugging and help
% purposes 
% OPTIONS:
% - see below the section of code showing all possible input options and comments for their meaning. 

% HISTORY
% - 13-Sep-2020 20:04:52 - created by Radek Chrapkiewicz (radekch@stanford.edu)


%% Summary preparation
summaryOut=summaryIn;
if nargin>=2
    summaryOut.contact=varargin{1};
else
    summaryOut.contact='Radek Chrapkiewicz (radekch@stanford.edu)'; % default for this package for now.
end
summaryOut.executionDuration=toc(summaryIn.executionDuration);

end  %%% END INITSUMMARY
