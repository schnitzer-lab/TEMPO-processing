function plotTimestamps(timestamps,summaryStructure)
% HELP
% Plots the time stamp output.
% SYNTAX
%[output_arg1,summary]= plotTimestamps(timestamps,summaryStructure)
%
% INPUTS:
% - timestamps - ...
% - summaryStructure - output summary of the 'getTimestamps' function
%
% OUTPUTS:
% - output_arg1 - ...
% - summary - %
% OPTIONS:
% - see below the section of code showing all possible input options and comments for their meaning. 

% HISTORY
% - 31-Aug-2020 12:21:03 - created by Radek Chrapkiewicz (radekch@stanford.edu)

subplot(2,2,1)
plot(timestamps)
xlabel('Frame (#)')
ylabel('Time stamp (s)')


subplot(2,2,2)
plot(summaryStructure.frames_dropped_vec)

xlabel('Frame (#)')
ylabel('Frames dropped')

subplot(2,2,3)
plot(summaryStructure.fpsvec)
xlabel('Frame (#)')
ylabel('Frame rate (fps)')

t=suptitle(sprintf('%s\n%i frames dropped',strrep(summaryStructure.dcimgFilePath,'\','\\'),...
    summaryStructure.frames_dropped_n));

t.FontSize=10;
t.FontName='Calibri';
set(gcf,'color','white');



subplot(2,2,4)
intervals=diff(summaryStructure.timestamps);
plot(intervals)

xlabel('Frame (#)')
ylabel('Frames intervals (ms)')

medintervals=median(intervals);
ylim([0.999*medintervals,1.001*medintervals]);


end  %%% END PLOTTIMESTAMPS
