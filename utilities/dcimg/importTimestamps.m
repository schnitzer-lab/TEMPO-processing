function [timestampVec]=importTimestamps(timestampsPath)
% HELP
% function imports times stamps as a vector from a file generated by 
% dct_readtimestamps.exe file
%
% SYNTAX
%[timestampVec]= importTimestamps(timestampsPath)
% INPUTS:
% - timestampsPath - path to the generated txt file with time stamps
%
% OUTPUTS:
% - timestampVec - imported vector of time stamps 

% HISTORY
% - 31-Aug-2020 12:54:33 - created by Radek Chrapkiewicz (radekch@stanford.edu)
% - 2021-06-14 11:24:55 - removing the last value as it was negative!  RC


opts = delimitedTextImportOptions("NumVariables", 1);
% Specify range and delimiter
opts.DataLines = [1, Inf];
opts.Delimiter = " ";
% Specify column names and types
opts.VariableNames = "timestamp";
opts.VariableTypes = "double";
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";
opts.ConsecutiveDelimitersRule = "join";
opts.LeadingDelimitersRule = "ignore";
% Import the data
tbl = readtable(timestampsPath, opts);

%% Convert to output type
timestampVec = tbl.timestamp;

timestampVec=timestampVec(1:end-1); % - 2021-06-14 11:24:55 -   RC

end  %%% END IMPORTTIMESTAMPS
