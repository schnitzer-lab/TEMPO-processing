function [timestampPath]=genTimestamps(dcimgFilePath, skip)
%
% HELP
% function generate a text file  for the time stapms with the exact same
% file path as DCIMG
% SYNTAX
%[timestampPath,summary]= genTimestamps(dcimgFilePath,reader_filename,reader_folderpath) - use 4, etc.
%[timestampPath,summary]= genTimestamps(dcimgFilePath,reader_filename,reader_folderpath,'optionName',optionValue,...) - passing options using a 'Name', 'Value' paradigm frequently used by Matlab native functions.
%[timestampPath,summary]= genTimestamps(dcimgFilePath,reader_filename,reader_folderpath,'options',options) - passing options as a structure.
%
% INPUTS:
% - dcimgFilePath - ...
% - reader_filename - ...
% - reader_folderpath - ...

% HISTORY
% - 31-Aug-2020 12:49:14 - created by Radek Chrapkiewicz (radekch@stanford.edu)
% - 2021-06-14 10:41:46 - fixing new dile name style with new time stamp exe program 06/21  RC
% - 2021-08-17 12:00 - added option for skipping if file exists

if(nargin < 2) skip = false; end

options.reader_filename='dct_readtimestamps.exe';
timestampPath=[dcimgFilePath,'.txt'];

if isfile(timestampPath) && skip
    disp("Skipping genTimestamps, " + timestampPath + " exists"); 
    return;
end

% options.reader_folderpath=fileparts(mfilename('fullpath'));
options.reader_folderpath=fullfile(fileparts(fileparts(fileparts(mfilename('fullpath')))),'dct_readtimestamps'); % - 2021-06-14 11:06:26 -   RC

if ~exist(options.reader_filename,'file')
    error('Cannot find %s, time stamp reader on the %s path!',options.reader_filename, options.reader_folderpath);
end

reader_path=fullfile(options.reader_folderpath,options.reader_filename);

if(strlength(dcimgFilePath) > 127-6) % if output file name'_0.txt' is longer than 127 symbols, dct_readtimestamps.exe fails
    error("dcimgFilePath needs to be shorter than 121 symbols for dct_readtimestamps.exe");
end

system(['"',reader_path,'"',' ','"', dcimgFilePath,'"']);
disps('File stamps generated')

timestampPathNewName=[dcimgFilePath,'_0.txt']; % previously it was just '.txt' suffix % - 2021-06-14 10:42:50 -   RC
if ~isfile(timestampPathNewName), error('time stamp not generated'); end
movefile(timestampPathNewName,timestampPath); % - 2021-06-14 10:45:42 -   RC

if isfile(timestampPath)
    disps('Timestamps successfully created');
else
    error('Timestamps file did not created');
end

end  %%% END GENTIMESTAMPS
