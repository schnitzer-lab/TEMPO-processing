function [movie,totalframes,summary]=loadDCIMG(filepath,varargin)
% Loading DCIMG file as a movie
% SYNTAX
% movie=loadDCIMG(filepath)
% movie=loadDCIMG(filepath,maxframe,...)  - loading from 1 to maxframe
% movie=loadDCIMG(filepath,[frameFirst, frameLast]) - loading selected
% range of frames
% movie=loadDCIMG(filepath,framerange,'Parameter',Value) - passing extra
% options with the 'Parameter', Value, Matlab style.
%
% INPUTS
% - filepath - path to the DCIMG file
% - maxframe, [frameFirst, frameLast] - frame indices
%
% OUTPUTS
% - movie - loaded movie
% - totalframes - total number of frames in the file
% - summary - extra information about the file and execution of this
% function.
%
% OPTIONS
% - 'resize' - enable spatial downsampling/binning
% - 'scaleFactor' -  e.g. ('scaleFactor', 0.5) to downsample by factor of 2x2 px.
% - see other available options in the code below
%
% DEPENDENCIES
% - Hamamatsu DCAM API installed
% - dcimgmatlab.mexw64 on a path
%
% HISTORY
%
% 02/2019 - created by Radek Chrapkiewicz (radekch@stanford.edu)
% 02/20/2019 - introducing options, such as rescale, RC
% 02/23/2019 - loading different number of frames, chunks etc.
% 10/24/2019 - add possible correction for path str when reading, by J.Li
% 11/29/2019 - adding parallel computing for speedup RC
% 11/29/2019 - seriously updated, removed all options and argument handling RC
% 05/29/2020 - adapting for VoltageImagingAnalysis without dependencies RC




%% OPTIONS
options.resize=false; % down sample spatially the file while loading? It speeds up loading especially combined with a parallel pool
options.parallel=true; % for parallel computing
options.binning=8; % default scale factor for spatial downsampling (binning).
options.outputType='single'; % 'uint16', 'double' - changing data type of the output movie but ONLY if you bin it spatially.

% display options
options.waitbar=false;
options.imshow=true; % for displaying the first frame after loading, disable on default
options.verbose=1; % 0 - nothing passed to command window, 1 (default) passing messages about state of the execution.

% not recommended to change below:
options.transpose=true; % we always transposed the original file to make
%it compatible with Matlab displays but it is swapping camera rows with columns
options.cropROI=[];


%% VARIABLE CHECK

% setting up a first frame
if nargin>=2
    switch length(varargin{1})
        case 0 % empty frame range
            startframe=int32(0); % indexing starts from 0 for the mex file!
            maxframe=int32(0);
        case 1 % movie=loadDCIMG(filepath,maxframe) TODO
            startframe=int32(0); % indexing starts from 0 for the mex file!
            maxframe=int32(varargin{1});
        case 2 % movie=loadDCIMG(filepath,[frameFirst, frameLast])
            startframe=int32(varargin{1}(1)-1); % indexing starts from 0 for the mex file!
            maxframe=int32(varargin{1}(2));
        otherwise
            error('Wrong format of a second argument of loadDCIMG function')
    end
else
    startframe=int32(0); % indexing starts from 0 for the mex file!
end

if nargin>=3
    options=getOptions(options,varargin(2:end)); % parsing options
end


if isempty(filepath)
    error('Empty DCMIMG path, somethign went wrong');
end


if ~ismember(options.outputType,{'single','double','uint16','uint8'})
        error('Data type %s not supported for movie cast typing',options.outputType)
end

%% SUMMARY PREPARATION
summary.input_options=options;
summary.execution_duration=tic;
summary.execution_started=datetime('now');

%%
summary.scaleFactor=1/options.binning;

if options.verbose; fprintf('\n'); disps('Start'); end

if options.waitbar
    hWaitBar = waitbar(0,'Opening DCIMG file...');
end

% loading first frame
disps('Loading first frame and file info.')
[framedata,totalframes]=  dcimgmatlab(startframe, filepath); % that's the mex file that should be on a path

if options.transpose
    framedata=framedata'; % this transposition is to make it compatible with imshow, but flips camera rows with columns
    % adding to summary file size information
end

% adding frame info to the summary at this point 
frame_info=whos('framedata');
summary.totalframes=totalframes;
summary.frame_size_original=size(framedata);
summary.firstframe_original=framedata;
% - 2020-07-18 16:17:24 - SH > should be done after imcrop and imresize...

if summary.scaleFactor~=1
    framedata=cast(framedata,options.outputType); % cast typing to preserve more information upon averaging
    framedata=imresize(framedata,summary.scaleFactor,'box');
    summary.frame_size_resized=size(framedata);
    summary.scaleFactor=summary.scaleFactor;
else
    summary.frame_size_resized=size(framedata);
    summary.scaleFactor=1;
end

% Done after imresize > ROI detected after resizing
if ~isempty(options.cropROI)
    % ORCA and matlab different XY convention
    framedata = imcrop(framedata, options.cropROI);
    summary.frame_size_postCropping=size(framedata);
    summary.cropROI=options.cropROI;
end

summary.frame_MB=frame_info.bytes/2^20;
summary.file_GB=frame_info.bytes*double(totalframes)/2^30;


if options.imshow
    imshow(framedata,[])
    title(filepath,'Interpreter','none','FontWeight','normal','FontSize',8);
end

% setting up the end frame, in the C indexing (starting from 0).
if ((maxframe==0)||(maxframe>=totalframes))
    endframe = int32(totalframes(1,1)-1);
else
    endframe=int32(maxframe-1);
end

numFrames = endframe - startframe+1;

summary.nframes2load=double(numFrames);
summary.frame_range=[startframe+1,endframe+1];
summary.loadedMB_fromDisk=double(numFrames)*summary.frame_MB;

if numFrames>totalframes
    error('Wrong frame indices!');
end

sizeFrame=size(framedata);

% Preallocate the array
movie = zeros(sizeFrame(1),sizeFrame(2),numFrames, class(framedata));
movie(:,:,1) = framedata;
progress=0;

%% main loading loop
frameidx=0;

%%% parallel loading
if options.parallel % for parallel computing
    
    disps('Starting loading DCIMG using PARALLEL mode (no progress will be reported).')
    
    %     % - 2020-07-18 15:05:33 - SH > get the option outside the parfor
    %     transpose=options.transpose;
    %     autoCrop=options.autoCrop;
    %     resize=options.resize; % they are redundant > remove resize...?
    %     scaleFactor=summary.scaleFactor;
    %     type=options.outputType;
    % ROI=options.cropROI;
    % - 2020-07-18 15:05:33 - SH > why int32 here?
    parfor ii=int32(1:numFrames) % indexing starts from 0 for the mex file!!!
        % Read each frame into the appropriate frame in memory.
        [framedata,~]=  dcimgmatlab(ii+startframe-1, filepath);
        
        if options.transpose
            framedata=framedata';
        end
        
        if summary.scaleFactor~=1
            framedata=cast(framedata,options.outputType); % cast typing to preserve more information upon averaging
            framedata=imresize(framedata,summary.scaleFactor,'box'); % this suprisingly gives speed up !
        end
        
        % Done after imresize > ROI detected after resizing
        if ~isempty(options.cropROI)
            % ORCA and matlab different XY convention
            framedata = imcrop(framedata, options.cropROI);
        end
        
        movie(:,:,ii)  = framedata; % for chunks loading it has to be frameidx not frame
    end
    disps('File loaded')
else
    
    %%% sequential loading
    
    disps('Starting loading DCIMG using sequential mode')
    disps(sprintf('Progress loading %d frames: ',endframe-startframe)); if options.verbose; fprintf('\b'); end
    refresh_idx=0;
    for frame=(startframe+1):endframe % indexing starts from 0 for the mex file!!!
        frameidx=frameidx+1;
        progress=double(frameidx)/double(numFrames);
        
        if rem(round(progress*100),5)==0
            refresh_idx=refresh_idx+1;
            if options.waitbar
                waitbar(progress,hWaitBar,'Loading DCIMG file     ');
            end
            if refresh_idx==1
                fprintf('%3d%%\n',round(progress*100))
            else
                fprintf('\b\b\b\b\b%3d%%\n',round(progress*100))
            end
        end
        
        % Read each frame into the appropriate frame in memory.
        [framedata,~]=  dcimgmatlab(frame, filepath);
        if options.transpose
            framedata=framedata'; % transposing is needed for imshow orientation compatibility
        end
        
        if summary.scaleFactor~=1
            framedata=cast(framedata,options.outputType); % cast typing to preserve more information upon averaging
            framedata=imresize(framedata,summary.scaleFactor,'box'); % this suprisingly gives speed up !
        end
        movie(:,:,frameidx+1)  = framedata; % for chunks loading it has to be frameidx not frame
    end
    if options.verbose; fprintf('\b'); end
    
    
end %% end choose if sequential of parallel
%%%%%%%%%%%%%%%%%%%


if options.waitbar
    waitbar(progress,hWaitBar,'Loading DCIMG file - finished');
    close(hWaitBar)
end

disps(sprintf('Loading DCIMG finished: %s',filepath));


%% Clearing MEX to immediately release RAM
clear mex; % 2019-11-29 16:12:11 RC - clearing mex buffer

%% SAVING SUMMARY
movie_info=whos('movie');
summary.loadedMB_toRAM=movie_info.bytes/2^20;
summary.execution_duration=toc(summary.execution_duration);

summary.frames_per_sec=summary.nframes2load/summary.execution_duration;
summary.MB_per_sec=summary.loadedMB_fromDisk/summary.execution_duration;
summary.movie_class=class(movie);
summary.filepath=filepath;
summary.function_path=mfilename('fullpath');

summary.contact='Radek Chrapkiewicz (radekch@stanford.edu)'; % in case of problems or suggestions

    function disps(string) %overloading disp for this function - this function should be nested
        FUNCTION_NAME='loadDCIMG';
        if options.verbose
            fprintf('%s %s: %s\n', datetime('now'),FUNCTION_NAME,string);
        end
    end

end % END of loadDCIMG






