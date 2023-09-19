
function [registeredimage, fixedframe, corn] = postcropping(registered_image, fixed_frame,corn)
% crop image to remove boundary values
% more advanced version, 2019-12-04 by Jizhou Li
% improved version, 2020-05-14 by Simon Haziza
% add corn output, 2020-06-07 by Jizhou Li
% add initilizing corn, 2020-06-09 by Jizhou Li

[fix_pad]=addZeroPadding(fixed_frame);
[reg_pad]=addZeroPadding(registered_image);

if nargin<3
    % needs to compute corn
    
% to get mask with 1 in the overlapping area
mask = ~isnan(registered_image);
[AugmentedMask]=addZeroPadding(mask);

% corn = pre_crop_nan(1-mask);
%registeredimage =  registeredimage(round(corn(2,1)): round(corn(2,2)), round(corn(1,1)): round(corn(1,3)));
%fixedframe =  fixed_frame(round(corn(2,1)): round(corn(2,2)), round(corn(1,1)): round(corn(1,3)));

LRout = LargestRectangle(AugmentedMask,0.1,0,0,0,0);%small rotation angles allowed
corn = [LRout(2:end,1) LRout(2:end,2)];
end

registeredimage =  reg_pad(round(corn(1,2)): round(corn(3,2)), round(corn(1,1)):round(corn(2,1)));
fixedframe =  fix_pad(round(corn(1,2)): round(corn(3,2)), round(corn(1,1)):round(corn(2,1)));

end

function [output]=addZeroPadding(input)
%add line and column of zero around mask
temp=cat(1,zeros(1,size(input,2)),input,zeros(1,size(input,2)));
output=cat(2,zeros(size(temp,1),1),temp,zeros(size(temp,1),1));
end