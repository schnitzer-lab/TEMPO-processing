function metrics = evalRegQualityMetrics(frameFixed, frameRegistered, varargin)
% Evaluation of the image registration performance between two images,
% frameMoving and frameFixed.
%
% SYNTAX:
% metrics= evalRegQualityMetrics(frameFixed, frameRegistered)
% metrics= evalRegQualityMetrics(frameFixed, frameRegistered, 'BandPass', true, 'BandPx', [0.05, 5])
% 
% INPUTS:
% - frameFixed - image of the fixed frame, provided as a reference
% - frameRegistered - image that aligned
%
% OUTPUTS:
% - metrics - structure containing a set of evaluation metrics
%       [HB] - The higher the better, [LB] - The lower the better
%   
%       'ssim': [HB] Structural similarity index. The SSIM metric combines local image structure, luminance, and contrast into a single local quality score. 
%               The SSIM quality metric agrees more closely with the
%               subjective quality score. The values range between 0 and 1.
%       'mse': [LB] Mean square error
%       'psnr': [HB] Peak signal-to-noise ratio,  derived from the mean square error, and indicates the ratio of the maximum pixel intensity to the power of the distortion.
%       'multissim': [HB] Multi-scale structural similarity index, which expands on the SSIM index by combining luminance information at the highest resolution level with structure and contrast information at several downsampled resolutions, or scales.
%       'diffphase': [LB] Global phase difference between the two images
%       'ncc': [HB] Normalized Cross-Correlation. The values range between 0 and 1.
%       'mae': [LB] Mean absolute error, see https://en.wikipedia.org/wiki/Mean_absolute_error
%       'struccont': [HB] Structural Content, which is defined by the squared ratio between two images
%       'maxdiff': [LB] Maximum difference
%       'piqe': [LB] Perception based image quality evaluator, unsupervised non-reference quality metric for the registered image.
%       
% OPTIONS:
% - 'bandpass': true (default) or false, whether to perform bandpass filtering of the images
% - 'low': the lower bound of bandpass filtering, default -Inf
% - 'high': the upper bound of bandpass filtering, default Inf
%
% HISTORY
% - 2020-05-29 16:12:60 - created by Jizhou Li (hijizhou@gmail.com)
% - 2020-06-03 21:40:22 - embedding bandpass filter, removing dependencies RC
% - 2020-06-07 14:29:12 - add pre-normalization before computing metrics, J. Li
% - 2020-06-09 23:20:45 - change the normalization way, J.Li
%
% ISSUES
% #1 - multissim available only in Matlab 2020(a) which is not a case for
% most of our computers ( 2020-06-01 15:47:25 RC) 
%
% TODO
% *1 - provide the option to output frame-by-frame metrics, and select the  in the case of two movies
% *2 - 3D normalized cross-correlation
% *3 - 3D bandpass filtering for the movies


% CONSTANTS (never change, use OPTIONS instead)
FUNCTION_AUTHOR='Jizhou Li (hijizhou@gmail.com)';


%% OPTIONS 
options.author=FUNCTION_AUTHOR;

options.normlization = true; % by default, normalize the image to the same range
options.BandPass=false; % perform bandpass filtering of the images first
options.BandPx=[0.01,2]; % spatial band expressed in pixels, input parameters to filters.BandPass2D function [options.BandPx(1)pass_cutoff,highpass_cutoff]

%% VARIABLE CHECK 

if nargin<2
	error('Wrong number of input arguments');
end

if nargin>=3
    options=getOptions(options,varargin(1:end)); % CHECK IF NUMBER OF THE OPTION ARGUMENT OK!
end

%% CORE

if options.normlization
    
    AdjustImage = @(x) (x - min(x(:))) ./ (max(x(:))-min(x(:)));
     disp('Normalizing frame by standard deviation');
    [frameFixed]=AdjustImage(frameFixed);
    [frameRegistered]=AdjustImage(frameRegistered);
end

if options.BandPass
    frameFixed = bpFilter2D(frameFixed,options.BandPx(1),options.BandPx(2));
    frameRegistered = bpFilter2D(frameRegistered,options.BandPx(1),options.BandPx(2));
%     metrics.BandPass = computeAllMetrics(frameFixed, frameRegistered); %
%     removing this, otherwise the output will change its standard
%     regarding the selected options. It won't pass the unittest checking
%     the output size.
end

metrics = computeAllMetrics(frameFixed, frameRegistered);

end

function metrics = computeAllMetrics(frameFixed, frameRegistered)
MULTISSIM_MATLAB_VER=9.8; % required  Matlab version to perform multissim RC

frameFixed = double(frameFixed); % in case of failing for some metrics
frameRegistered = double(frameRegistered); 

[m1, n1, t1] = size(frameFixed);
[m2, n2, t2] = size(frameRegistered);

if (m1~=m2) || (n1~=n2) || (t1~=t2)
    error('The size of two images does not match');
end

% SSIM
metrics.ssim = ssim(frameFixed, frameRegistered);
% MSE
metrics.mse = immse(frameFixed, frameRegistered);
% PSNR
metrics.psnr = psnr(frameFixed, frameRegistered, max(frameFixed(:)));
% multissim
if matlabVersion < MULTISSIM_MATLAB_VER % RC
    metrics.multissim=0;
%     disp('Your Matlab verssion does not support multissim quality metric');
else
    if t1>1
        metrics.multissim = multissim3(frameFixed, frameRegistered);
    else
        metrics.multissim = multissim(frameFixed, frameRegistered);
    end
end

% diffphase
if t1>1
    fftFixed = fftn(frameFixed);
    fftRegistered = fftn(frameRegistered);
else
    %2d
    fftFixed = fft2(frameFixed);
    fftRegistered = fft2(frameRegistered);
end
CC = sum(fftFixed(:).*conj(fftRegistered(:)));
metrics.diffphase = angle(CC);

% Normalized Cross-Correlation
frameFR = frameFixed .* frameRegistered;
frameFF = frameFixed .* frameFixed;
frameRR = frameRegistered .* frameRegistered;

metrics.ncc = sum(frameFR(:)) / sum(frameFF(:));

% Max absolute error
metrics.mae = norm(frameFixed(:)-frameRegistered(:),1) / (m1*n1*t1);

% Structural Content
metrics.struccont = sum(frameFF(:)) / sum(frameRR(:));

% Maximum difference
diffFR = frameFixed - frameRegistered;
metrics.maxdiff = max(diffFR(:));

if t1>1
    metrics.piqe = NaN;
else
    metrics.piqe = piqe(frameRegistered);
end


end

function ver=matlabVersion()
% 2020-06-01 15:50:50 RC
        version_string=version;
        ver=sscanf(version_string(1:3),'%f');
end



function [output]=bpFilter2D(input,low,high)

stack=double(input);

fwhm_scaling=2*sqrt(2*log(2));

output=stack;
sz=size(stack);
if length(sz)==2
    sz=[sz,1];
end

for ii=1:sz(3)
    if low==Inf
        output(:,:,ii)=imgaussfilt(squeeze(stack(:,:,ii)),high/fwhm_scaling,'FilterDomain','spatial');
    else
        output(:,:,ii)=...
            imgaussfilt(squeeze(stack(:,:,ii)),high/fwhm_scaling,'FilterDomain','spatial')...
            -imgaussfilt(squeeze(stack(:,:,ii)),low/fwhm_scaling,'FilterDomain','spatial');
    end
end
end