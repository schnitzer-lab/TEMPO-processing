function [dcimgPath]=findDCIMG(h5path,varargin)
%
% HELP
% Finding a raw dcimg file, corresponding to the processed h5 file.
% SYNTAX
%[dcimgPath]= findDCIMG() - use 1 if no arguments are allowed
%[dcimgPath]= findDCIMG(h5path) - use 2, etc.
%[dcimgPath]= findDCIMG(h5path,'optionName',optionValue,...) - passing options using a 'Name', 'Value' paradigm frequently used by Matlab native functions.
%[dcimgPath]= findDCIMG(h5path,'options',options) - passing options as a structure.
%
% INPUTS:
% - h5path - ...
%
% OUTPUTS:
% - dcimgPath - ...
% - summary - %
% OPTIONS:
% - see below the section of code showing all possible input options and comments for their meaning. 

% HISTORY
% - 28-Aug-2020 19:02:51 - created by Radek Chrapkiewicz (radekch@stanford.edu)
%
% ISSUES
% #1 - issue 1
%
% TODO
% *1 - get the first working version of the function!



%% OPTIONS (Biafra style, type 'help getOptions' for details) or: https://github.com/schnitzer-lab/VoltageImagingAnalysis/wiki/'options':-structure-with-function-configuration
options=struct; % add your options below 
options.storageType='ColdDCIMGStorage7'; % according to 'voltPaths' nomenclature 


%% VARIABLE CHECK 

if nargin>=2
options=getOptions(options,varargin(1:end)); % CHECK IF NUMBER OF THE OPTION ARGUMENT OK!
end


%% CORE

[~,~,ext]=fileparts(h5path);
if strcmpi(ext,'.dcimg')
    dcimgPath=h5path;
    disps('You already provied a dcimg path rather than expected H5 input. Fine, terminating.')
    return;
elseif strcmpi(ext,'.h5')
    % that's a default
else 
    disps('Wrong path')
    error('Expected h5 file path on the input');
end


vPathsStructure=voltPaths(fileparts(h5path));

isGreen = contains(h5path,'-cG');
isRed = contains(h5path,'-cR');

folderPath=vPathsStructure.(options.storageType);

if isGreen
    fileList=rdir(fullfile(folderPath,'*-cG*.dcimg'));
elseif isRed
    fileList=rdir(fullfile(folderPath,'*-cR*.dcimg'));
else
    error('H5 file stem do not have -cG nor -cR in the file name');
end

if isempty(fileList)
    warning('No DCIMG files found');
    dcimgPath='';
    return
elseif length(fileList)>1
    warning('More than 1 dcimg files found, disambiguity')
    beep;
    disp(fileList);
end

dcimgPath=fileList(1).name;

end  %%% END FINDDCIMG
