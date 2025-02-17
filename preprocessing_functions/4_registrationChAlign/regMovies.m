function [fixedV,registeredV,summary] = regMovies(fixed, moving,varargin)
%% REGMOVIES: Video registration
% [fixedV,registeredV,summary] = regMovies(fixed, moving)
% [fixedV,registeredV,summary] = regMovies(fixed, moving,Parameter,Value,...)
%
% INPUT:
%       fixed   = The fixed video as a reference, can be variable loaded in
%                   memory or a pointer to a h5 file
%       moving  = The video to be registered
% OUTPUT:
%       registeredV  = The output registered video
%       fixedV - fixed video cropped to match the size of the original
%       movie
%       summary     = Extra outputs, validation and diagnostic
%
% OPTIONS SYNTAX
% regMovies(fixed,moving,'options',options);
% regMovies(fixed,moving,'BandPass',false,'options',options);
%
%
% CONTACT: Jizhou Li (hijizhou@gmail.com)
% HISTORY
% Created: 17 June, 2019
% 2020-05-07 add default flip
% 2020-05-14 switch reg method from pre_reg_frame_v2 to imageReg
% 2020-06-03 adapted for VoltageImagingAnalysis common package by Radek Chrapkiewicz
% 2020-06-07 add hybrid registration to choose the best method, J. Li
% 2020-06-09 add support for h5 files (over the memory limits), J. Li
% 2020-06-27 01:54:01 Replaced all 3rd dimensions of h5 chunks to 1. RC
% 2020-06-27 05:12:39 Getting rid of clearvars, causing bugs RC
% 2020-06-29 22:07:56 chunking based on RAM for clean output RC
% this function disappeared 08/2020
%
% TODO
% - plotting
% - validation

%% OPTIONS specified below:

options.BandPass=true; % perform bandpass filtering of the images first
options.BandPx=[1,10];% spatial band expressed in pixels, input parameters to filters.BandPass2D function [options.BandPx(1)pass_cutoff,highpass_cutoff]
% the first value responsible for lowpass, should be super small

options.ChunkSize = []; % if empty, this will be calculated based on RAM RC
options.maxRAM=0.01;

options.Normalize=true;

options.Binarize=false; % only hard cases where there is a lot of features that are small
options.Threshold=false; % only hard cases where there is a lot of features that are small
options.ThresholdValue=0;

options.TemplateFrame=[]; 
options.interp = 'linear';% imwarp interpolation method
options.shifts0 = [0,0];

% display control
options.plot=true;
options.addmetah5=false;
options.verbose=1; % 0 - supress displaying state of execution

options.dataset= ['/', 'mov'];

options.docrop = true;
options.skip = false;
%% VARIABLE CHECK

if nargin>=3
    options=getOptions(options,varargin);
end

%% SUMMARY PREPARATION
summary.funcname = 'reg';
fname_Suffix=['_',summary.funcname];
if ~(Suffix.is(fname_Suffix)); error('not a valid Suffix'); end
summary.input_options=options;
summary.function_path=mfilename('fullpath');
summary.execution_started=datetime('now');
summary.execution_duration=tic;

%% CORE

if ischar(fixed) % passing movie as filepth to h5 files
    if ~isfile(fixed); error('Not a file'); end
    [~,~,ext] = fileparts(fixed);
    ext = ext(2:end);
    if strcmpi(ext,'hdf5') || strcmpi(ext,'h5');
        filetype = 'hdf5';        
        dims_fixed=h5moviesize(fixed,'dataset',options.dataset);
        dims_moving=h5moviesize(moving,'dataset',options.dataset);        
        num_frame_fixed = dims_fixed(end);

        num_frame_moving = dims_moving(end);
        
        if num_frame_fixed~=num_frame_moving
            warning('Number of frames are not equal');
            % - 2021-08-27 14:26:31 - to remove errors in case recording have been stopped asynchronously   RC
%             if num_frame_fixed<num_frame_moving
%                 moving=moving(:,:,1:num_frame_fixed);
%                 num_frame_moving=num_frame_fixed;
%             else
%                 fixed=fixed(:,:,1:num_frame_fixed);
%                 num_frame_fixed=num_frame_moving;
%             end
        end
        
        if isempty(options.TemplateFrame)
            options.TemplateFrame=num_frame_fixed; % which frame to take as a template ? on default the last one.
        end
        fixed_frame =  h5read(fixed,options.dataset,[1,1,options.TemplateFrame],[dims_fixed(1:end-1),1]);
        moving_frame =  fliplr(h5read(moving,options.dataset,[1,1,options.TemplateFrame],[dims_moving(1:end-1),1]));
         datatype = class(fixed_frame);
        % output file names

        suff_obj_fixed=Suffix(fixed);
        fixedV=suff_obj_fixed.change(fname_Suffix); % handling changing Suffixes through class Suffix to avoid multiple adding of Suffixes and not allowed ones. This causes a problem for automatic file search.

        suff_obj_moving=Suffix(moving);
        registeredV=suff_obj_moving.change(fname_Suffix);
        
        if( isfile(fixedV) &&  isfile(registeredV) && options.skip)
            disp("regMovies: Output file exists. Skipping: " + fixedV);
            return;
        end
    else
        error('Filetype %s not supported',ext);
    end
else % array loaded in memory
    options.ChunkSize = [];
    
    filetype = 'mat';
    dims_fixed = size(fixed);
    dims_moving = size(moving);    
    num_frame_fixed = dims_fixed(end);    
    options.TemplateFrame=num_frame_fixed; % which frame to take as a template ? on default the last one.
    fixed_frame = fixed(:,:,options.TemplateFrame);
    moving_frame = fliplr(moving(:,:,options.TemplateFrame));
end

num_frame = num_frame_fixed;

% outputing some basic info about the processed movie
summary.filetype = filetype;
summary.nframes=num_frame;
summary.fixed_size=dims_fixed;
summary.moving_size=dims_moving;
summary.original_type=[class(fixed_frame),',',class(moving_frame)];

fprintf('\n'); disp('Registering the template frame');

summary.orig_fixed_frame=fixed_frame;
summary.orig_moving_frame=moving_frame;

summary.sim_metrics_before = evalRegQualityMetrics(fixed_frame, moving_frame, 'BandPass',false);
%%

fixed_frame = imputeNaNS(fixed_frame); 
moving_frame = imputeNaNS(moving_frame);
%% 1. Estimation of the transformation

if options.plot
    % multiple plots are not great and causing clutter. Better get one good
    % figure in the end summarizing them all. RC
    plotting(fixed_frame,moving_frame)
    sgtitle('Fixed and moving frame before processing')
    drawnow
end

% Bandpass filter to sharpen the features
if options.BandPass
    disp('Bandpassing single frame')
    fixed_frame=bpFilter2D(fixed_frame,options.BandPx(1),options.BandPx(2)); % high pass filter
    moving_frame=bpFilter2D(moving_frame,options.BandPx(1),options.BandPx(2)); % high pass filter
end

summary.sim_metrics_before_bandpassed = evalRegQualityMetrics(fixed_frame, moving_frame, 'BandPass',false);

if options.plot
    figure(2);
    plotting(fixed_frame,moving_frame)
    sgtitle('Fixed and moving frame after bandpassing')
    drawnow
end

% normalize the frame intensity
if options.Normalize
    disp('Normalizing frame by standard deviation');
    [fixed_frame]=AdjustImage(fixed_frame);
    [moving_frame]=AdjustImage(moving_frame);
end

if options.Threshold
    fixed_frame(fixed_frame<options.ThresholdValue)=0;
    moving_frame(moving_frame<options.ThresholdValue)=0;
end

if options.Binarize
    disp('Binarizing images');
    fixed_frame=double(imbinarize(fixed_frame));
    moving_frame=double(imbinarize(moving_frame));
end

summary.fixed_frame=fixed_frame;
summary.moving_frame=moving_frame;
%%

disp('Registering the template frame');
[Reg,regMethod, regScore] = imageReg(fixed_frame, moving_frame, options.interp, options.shifts0);
disp('Transformation found');

reg_frame=Reg.RegisteredImage;
summary.reg_frame=reg_frame;
summary.regScore = regScore;
summary.regMethod = regMethod;


% Default spatial referencing objects
fixedRefObj = imref2d(size(fixed_frame));
movingRefObj = imref2d(size(Reg.RegisteredImage));

if options.plot
    figure(3)
    disp('Plotting');
    plotting(fixed_frame,reg_frame)
end


summary.sim_metrics_before_bandpassed = evalRegQualityMetrics(fixed_frame, moving_frame, 'BandPass',false);
transformation=Reg.transformation;% to not broadcast the whole variable
summary.translation=transformation.T(3,1:2);
summary.angle=asin(transformation.T(2,1))*180/pi;

disp('Applying affine transform the original template and moving frame');
RegisteredImage = imwarp(summary.orig_moving_frame, movingRefObj, transformation,...
    'OutputView', fixedRefObj, 'SmoothEdges', true, 'FillValues', NaN, 'interp', options.interp);
if(options.docrop)
    [registered_cropped,fixed_cropped, corn] = postcropping(RegisteredImage,summary.orig_fixed_frame);
else
    registered_cropped=RegisteredImage;
    fixed_cropped=summary.orig_fixed_frame;
    corn = [1,1; size(registered_cropped,2), 1; ...
            flip(size(registered_cropped)); 1, size(registered_cropped,1) ];
    fixed_cropped(isnan(fixed_cropped)) = 0;
    registered_cropped(isnan(registered_cropped)) = 0;
end

summary.fixed_cropped=fixed_cropped;
summary.registered_cropped=registered_cropped;
croppeddims = size(fixed_cropped);
summary.croppeddims = croppeddims;

if options.plot
    figure(4)
    plotting(fixed_cropped,registered_cropped)
    drawnow
end

summary.sim_metrics_after = evalRegQualityMetrics(fixed_cropped, registered_cropped, 'BandPass',false);
summary.sim_metrics_after_bandpassed = evalRegQualityMetrics(fixed_cropped, registered_cropped, 'BandPass',true,'BandPx',options.BandPx);

metrics=summary.sim_metrics_before;
metrics(2)=summary.sim_metrics_after;
metrics(3)=summary.sim_metrics_before_bandpassed;
metrics(4)=summary.sim_metrics_after_bandpassed;
metrics=struct2table(metrics);
metrics.Properties.RowNames={'Before','After','Before BP','After BP'};

summary.metrics_table=metrics;
metrics

if (summary.sim_metrics_after.ssim<summary.sim_metrics_before.ssim)...
        &&  (summary.sim_metrics_after.psnr<summary.sim_metrics_before.psnr)...
        && (summary.sim_metrics_after.ncc<summary.sim_metrics_before.ncc)
    summary.status=false;
    summary.status_message='Registration failed';
else
    summary.status=true;
    summary.status_message='Looks good';
end

%% 2. Applying the estimate transofmration to all data

if strcmpi(filetype,'mat')
    % disp('Preallocating output movies') % allocation added by RC to speed up the function
    registeredV=zeros(size(fixed_cropped,1),size(fixed_cropped,2),size(moving,3),class(moving));
    fixedV=registeredV;    
%     clearvars -except num_frame moving fixed registeredV fixedV
%     movingRefObj transformation fixedRefObj summary options corn %
%     causing bugs!
    disp(['Applying transformation to all ' num2str(num_frame) ' frames....']);
    parfor i=1:num_frame % changed for regular for for testing  RC 2020-05-29
        moving_frame = fliplr(moving(:,:,i)); % this should be fliplr specifically ! % 2020-06-03 20:03:47 RC
        fixed_frame = fixed(:,:,i);        
        [registeredimage,fixedframe] = applyReg2frame(fixed_frame,moving_frame,transformation,corn, options.interp, options.docrop ); % fixed missing transformation RC        
        registeredV(:,:,i) = registeredimage; % those matrices should be allocated before, otherwise it's taking long to increase the size % 2020-06-03 20:09:45 RC
        fixedV(:,:,i) = fixedframe;        
    end
    
    summary.output_type=[class(fixedV),',',class(registeredV)];
    
else % h5 file
    
    % create the files, registeredV,fixedV 
    if isfile(registeredV)
        disp('Founded a registeredV file, deleting')
        delete(registeredV);
    end
    if isfile(fixedV)
        disp('Founded a fixedV file, deleting')
        delete(fixedV);
    end
        

    if isempty(options.ChunkSize)
        disp('Finding a chunk size based on available RAM.')
       options.ChunkSize=chunkh5(fixed,options.maxRAM);
    end
    
    for fi = 1:options.ChunkSize:num_frame
        sframe = fi; % start frame
        endframe = min(sframe+options.ChunkSize, dims_fixed(end));
        realframe = min(options.ChunkSize, dims_fixed(end)-sframe+1);
        data_moving = h5read(moving,options.dataset,[ones(1,length(dims_fixed)-1),sframe],[dims_fixed(1:end-1),realframe]);
        data_fixed = h5read(fixed,options.dataset,[ones(1,length(dims_fixed)-1),sframe],[dims_fixed(1:end-1),realframe]);
        
        % preallocate
       
        transformed_moving = zeros([size(fixed_cropped),realframe],class(data_moving));
        transformed_fixed = zeros([size(fixed_cropped),realframe],class(data_moving));
        
        disp( ['processing frames ' num2str(sframe) ' - ' num2str(endframe) ', in total ' num2str(dims_fixed(end)) ' frames']);
        
        parfor ii=1:realframe
            % Jizhou, you may have forgotten about flipping... - 2020-06-30 04:20:45 -   RC
            moving_frame = fliplr(data_moving(:,:,ii)); % this should be fliplr specifically RC
            [registeredimage,fixedframe] = applyReg2frame(data_fixed(:,:,ii), moving_frame, transformation,corn, options.interp, options.docrop);            
            transformed_moving(:,:,ii) = registeredimage;
            transformed_fixed(:,:,ii) = fixedframe;            
        end
        
        h5append(registeredV,single(transformed_moving),options.dataset);
        h5append(fixedV,single(transformed_fixed),options.dataset);        
    end
    
end

disp(['Finished - ' summary.funcname]);

%% VALIDATION

% summary.status=true; % it worked
% summary.quality_metrics

%%
summary.postcroppingcorn = corn;
summary.transformation=transformation;
summary.execution_duration=toc(summary.execution_duration);

% if strcmpi(filetype,'hdf5')
%     h5save(registeredV,summary,'summary_regMovies');
%     h5save(fixedV,summary,'summary_regMovies');
% end

function disp(string) %overloading disp for this function
if options.verbose
    fprintf('%s regMovies: %s\n', datetime('now'),string);
end
end
end



function [registeredimage,fixedframe,corn] = applyReg2frame(fixed, moving, transformation,corn, interp, docrop)
fixedRefObj = imref2d(size(fixed));
movingRefObj = imref2d(size(moving));
RegisteredImage = imwarp(moving, movingRefObj, transformation, 'OutputView', fixedRefObj, 'SmoothEdges', true, 'FillValues', NaN, 'interp', interp);

if(docrop)
    [registeredimage,fixedframe,corn] = postcropping(RegisteredImage,fixed,corn);
else
    registeredimage = RegisteredImage;
    fixedframe = fixed;
end
end


function [output]=AdjustImage(input)
avg = mean2(input);
sigma = std2(input);
% Adjust the contrast based on the standard deviation.
output = (input-avg)./sigma;
end


function plotting(fixed_frame,moving_frame)
% by RC
subplot(2,2,[1,2])
imshowpair(fixed_frame,moving_frame,'montage')
title('Fixed, moving')
subplot(2,2,3)
imshowpair(fixed_frame,moving_frame)
subplot(2,2,4)
imshowpair(fixed_frame,moving_frame,'diff')
title('Difference')
end


