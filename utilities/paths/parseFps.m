function fps=parseFps(filePath)
% HELP PARSEFPS.M
% Parsing frame rate (fps) from the file name or file path.
% SYNTAX
% fps=parseFps(filePath)
%
% INPUTS
% - filePath - can be relative or absolute paths, expecting to see '-fps'
% regular expression in the file name 

% HISTORY
% - 03-Oct-2020 10:56:13 - created by Radek Chrapkiewicz (radekch@stanford.edu)

[~,endIndex] = regexp(filePath,'-fps');
fps=sscanf(filePath((endIndex+1):end),'%f');
end  %%% END PARSEFPS

