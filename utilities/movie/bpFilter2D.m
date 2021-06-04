function [output]=bpFilter2D(movie,low,high)
% bandpassing movie
% by RC 2018
% modified by SH, JL
% - 2021-05-17 17:04:53 - added highpass if low =0  RC

movie=double(movie);

fwhm_scaling=2*sqrt(2*log(2));

output=movie;
sz=size(movie);
if length(sz)==2
    sz=[sz,1];
end

for ii=1:sz(3)
    if high==Inf
        output(:,:,ii)=imgaussfilt(squeeze(movie(:,:,ii)),low/fwhm_scaling,'FilterDomain','spatial');
    elseif low==0 % - 2021-05-17 17:05:33 -   RC
        output(:,:,ii)=...
            imgaussfilt(squeeze(movie(:,:,ii)),high/fwhm_scaling,'FilterDomain','spatial')...
            -movie(:,:,ii);
    else
        output(:,:,ii)=...
            imgaussfilt(squeeze(movie(:,:,ii)),high/fwhm_scaling,'FilterDomain','spatial')...
            -imgaussfilt(squeeze(movie(:,:,ii)),low/fwhm_scaling,'FilterDomain','spatial');
    end
end

disps('Bandpassed')
end