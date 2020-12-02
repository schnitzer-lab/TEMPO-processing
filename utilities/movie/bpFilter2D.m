function [output]=bpFilter2D(input,low,high)
% bandpassing movie
% by RC, modified by SH, JL
stack=double(input);

fwhm_scaling=2*sqrt(2*log(2));

output=stack;
sz=size(stack);
if length(sz)==2
    sz=[sz,1];
end

for ii=1:sz(3)
    if high==Inf
        output(:,:,ii)=imgaussfilt(squeeze(stack(:,:,ii)),low/fwhm_scaling,'FilterDomain','spatial');
    else
        output(:,:,ii)=...
            imgaussfilt(squeeze(stack(:,:,ii)),high/fwhm_scaling,'FilterDomain','spatial')...
            -imgaussfilt(squeeze(stack(:,:,ii)),low/fwhm_scaling,'FilterDomain','spatial');
    end
end

disps('Bandpassed')
end