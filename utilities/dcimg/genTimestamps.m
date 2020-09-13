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
options.reader_filename='dct_readtimestamps.exe';
options.reader_folderpath=fileparts(mfilename('fullpath'));

if ~exist(options.reader_filename,'file')
    error('Cannot find %s, time stamp reader on the %s path!',options.reader_filename, options.reader_folderpath);
end

reader_path=fullfile(options.reader_folderpath,options.reader_filename);

system(['"',reader_path,'"',' ',dcimgFilePath]);
disps('File stamps generated')

timestampPath=[dcimgFilePath,'.txt'];

if exist(timestampPath,'file')
    disps('Timestamps successfully created');
else
    error('Timestamps file did not created');
end

end  %%% END GENTIMESTAMPS
