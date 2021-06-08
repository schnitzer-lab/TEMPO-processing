function [h5path,summary]=convertRaw2Preproc1(dcimgPath,varargin)
% HELP CONVERTRAW2PREPROC1.M
% Converts DCIMG file, generates time stamps and copy all assosiated metadata files to the preprocessed folder.
% '1' in the file name, indicate the steps will be done only for one channel file
% SYNTAX
%[h5path,summary]= convertRaw2Preproc1(dcimgPath)
%[h5path,summary]= convertRaw2Preproc1(dcimgPath,'optionName',optionValue,...) - passing options using a 'Name', 'Value' paradigm frequently used by Matlab native functions.
%[h5path,summary]= convertRaw2Preproc1(dcimgPath,'options',options) - passing options as a structure.
%
% INPUTS:
% - dcimgPath - path to the raw DCIMG file
%
% OUTPUTS:
% - h5path - path output h5 file
% - summary - extra information about the processing
% OPTIONS:
% - see below the section of code showing all possible input options and comments for their meaning.

% HISTORY
% - 06-Oct-2020 23:09:13 - created by Radek Chrapkiewicz (radekch@stanford.edu)
% - 2021-04-28 - added useDCIMGmex option for alternative mex file to read
% .dcimg and moved default options to the separate function ( defaultOptions )

%% OPTIONS (type 'help getOptions' for details)
options=defaultOptions(dcimgPath);

%% VARIABLE CHECK
if nargin>=2
    options=getOptions(options,varargin(1:end)); % CHECK IF NUMBER OF THE OPTION ARGUMENT OK!
end
if(strcmp(options.expPath, "DEFAULT"))
    folderPath=fileparts(dcimgPath);
    vpaths=voltPaths(folderPath);
    options.expPath=vpaths.PreprocessingStorage;
end
summary=initSummary(options);


%% CORE
disps(sprintf('Converting: %s',dcimgPath));
[folderPath,fileName]=fileparts(dcimgPath);

h5path=fullfile(options.expPath,[fileName '.h5']);

if isfile(h5path) && options.skip
    disps(sprintf('File %s exists, skipping\n',h5path));
    return
else
    disps(sprintf('File does not %s exists, converting\n',h5path));
    disps('First generating time stamps');
    try
    genTimestamps(dcimgPath);
    catch
        warning('No time stamps!')
    end
    mkdirs(options.expPath);
    
    disps('Then copying metadata')
    [copied_filelist,found_filelist,summaryLVmeta]=copyLVmeta(folderPath,options.expPath);
    [metadata]=importLvMetaData(summaryLVmeta.LVfolder);
    summary.LVmetadata=metadata;
    
    sowtwarebinning=options.binning;
    if isfield(metadata,'hardwareBinning')
        sowtwarebinning=options.binning/metadata.hardwareBinning;
        if metadata.hardwareBinning==1
            disps('No binning detected, sticking to default software binning');
        else
            disps(sprintf('Found %d hardware binning, changing the software binning to %.2f',metadata.hardwareBinning,sowtwarebinning))
        end        
    else 
        disps('Did not find hardware binning for LV metadata');
    end
    
    disps('And actual convertion');
    [~,summary.loadDCIMG]=loadDCIMGchunks(dcimgPath,[],...
        'binning',sowtwarebinning, 'h5path',h5path, 'maxRAM', options.maxRAM,...
        'parallel', options.parallel, 'useDCIMGmex', options.useDCIMGmex);
    disps('Analyzing frame rate')
    
    try
        [fps,nDroppedFrames,summary.getFps]=getFps(dcimgPath);
    catch ME
        getReport(ME)
        disps('Cannot get fps from the DCIMG file');
        fps=[];
        nDroppedFrames=[];
    end
    
    disps('Adding extra data to h5 file');
    
    convertionDate=sprintf('%s',datetime('now','Format','yyyy-MM-dd HH:mm:ss'));
    fileInfo=rdir(dcimgPath);    
    if(~options.useMovieSpecs) %Radek's way
        if ~isempty(fps), h5save(h5path,fps); end
        if ~isempty(nDroppedFrames), h5save(h5path,nDroppedFrames); end

        h5save(h5path,sowtwarebinning,'/binning');
        h5save(h5path,metadata.hardwareBinning,'/hardwareBinning');
        h5save(h5path,dcimgPath,'/sourcePath');
        h5save(h5path,convertionDate);
        h5save(h5path,fileInfo(1).date,'/recordingDate');
    else %Vasily's way
        % for consistency with Radek's code:
        extra_specs = containers.Map({'hardwareBinning', 'convertionDate', 'recordingDate'},...
                                     {metadata.hardwareBinning, convertionDate, fileInfo(1).date}); 
        
        st = dbstack; functionname = st.name;                      
        movie_specs = MovieSpecs(functionname, fps, options.pixsize/options.binning,... 
                                 sowtwarebinning, [1,1], 1, 1, dcimgPath, extra_specs);
        rw.h5saveMovieSpecs(h5path, movie_specs);
        
        summary=closeSummary(summary);
        h5save(h5path, summary,  functionname);
    end
end



%% CLOSING
disps('Done');
if(~options.useMovieSpecs) summary=closeSummary(summary); end %Radek's way 

end  %%% END CONVERTRAW2PREPROC1


function options =  defaultOptions(dcimgPath)
    options.verbose=true;
    
    options.useMovieSpecs = false;
    options.pixsize = 2^10; %TODO: Needs to be updated + not the best way to introduce it
    
    options.binning=8;
    options.skip=false;
    options.maxRAM = 0.1;
    options.parallel = true;
    
    options.expPath="DEFAULT";
    
    options.useDCIMGmex = false; %Alternative mex file for dcimg - Vasily
end
