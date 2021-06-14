function [timestampPath]=genTimestamps(dcimgFilePath,varargin)
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

options.reader_filename='dct_readtimestamps.exe';
% options.reader_folderpath=fileparts(mfilename('fullpath'));
options.reader_folderpath=fullfile(fileparts(fileparts(mfilename('fullpath'))),'dct_readtimestamps'); % - 2021-06-14 11:06:26 -   RC

if ~exist(options.reader_filename,'file')
    error('Cannot find %s, time stamp reader on the %s path!',options.reader_filename, options.reader_folderpath);
end

reader_path=fullfile(options.reader_folderpath,options.reader_filename);

system(['"',reader_path,'"',' ',dcimgFilePath]);
disps('File stamps generated')

timestampPathNewName=[dcimgFilePath,'_0.txt']; % prewviously it was just '.txt' suffix % - 2021-06-14 10:42:50 -   RC
timestampPath=[dcimgFilePath,'.txt'];
if ~isfile(timestampPathNewName), error('time stamp not generated'); end
movefile(timestampPathNewName,timestampPath); % - 2021-06-14 10:45:42 -   RC

if isfile(timestampPath)
    disps('Timestamps successfully created');
else
    error('Timestamps file did not created');
end

end  %%% END GENTIMESTAMPS
