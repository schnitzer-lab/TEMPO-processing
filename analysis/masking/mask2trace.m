function [timeTrace,summary]=mask2trace(movie,mask,varargin)
% HELP MASK2TRACE.M
% Masking movie and creating a corresponding time trace from the summed pixels within a mask.
% SYNTAX
%[timeTrace,summary]= mask2trace(movie,mask) - use 3, etc.
%[timeTrace,summary]= mask2trace(movie,mask,'optionName',optionValue,...) - passing options using a 'Name', 'Value' paradigm frequently used by Matlab native functions.
%[timeTrace,summary]= mask2trace(movie,mask,'options',options) - passing options as a structure.
%
% INPUTS:
% - movie - ...
% - mask - ...
%
% OUTPUTS:
% - timeTrace - ...
% - summary - %
% OPTIONS:
% - see below the section of code showing all possible input options and comments for their meaning. 

%
% HISTORY
% - 15-Dec-2020 17:20:18 - created by Radek Chrapkiewicz (radekch@stanford.edu)
% - 2021-06-04 15:24:52 - 5x faster implementation  RC

%% OPTIONS (type 'help getOptions' for details)
options=struct; % add your options below 
options.plot=false;

%% VARIABLE CHECK 
if nargin>=3
options=getOptions(options,varargin(1:end)); % CHECK IF NUMBER OF THE OPTION ARGUMENT OK!
end
summary=initSummary(options);


%% CORE
%The core of the function should just go here.

% slow implementation:
% mask=cast(mask,class(movie));
% maskedMovie=mask.*movie;
% timeTrace=sum(maskedMovie,[1,2]);
% timeTrace=squeeze(timeTrace);

mask2D=to2D(mask);
movie2D=to2D(movie);

indPositive=mask2D>0;
timeTrace=mean(movie2D(indPositive,:),1, 'omitnan');

if options.plot
    plot(timeTrace)
    xlabel('Frames (#)')
    formatPlot
end 



%% CLOSING
summary=closeSummary(summary);
end  %%% END MASK2TRACE