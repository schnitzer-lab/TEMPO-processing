function varargout=checkRAM()
% Checking amount of available RAM on the computer (in bytes)
% SYNTAX
%  checkRAM() - prints the information about the RAM into the command line
% [availableRAM,summary]= checkRAM()
%
% INPUTS:
% - noinputts
%
% OUTPUTS:
% - availableRAM - available RAM in bytes
% - summary - structure containing an internal configuration and extra
% outputs
%
% OPTIONS:
% - no extra options here
%
% HISTORY
% - 2019-02 - originally created by Radek Chrapkiewicz
% (radekch@stanford.edu) for Recording class
% - 2019 - upgraded by Jizhou Li for different machine types.
% - 2020-06-02 13:11:38 - rewritten adapted for VoltageImagingAnalysis by RC.
%
% ISSUES
% #1 - issue 1
%
% TODO
% *1 - get the first working version of the function!



%% Summary preparation
summary.function_path=mfilename('fullpath');
summary.execution_started=datetime('now');
summary.execution_duration=tic;


%% CORE
%The core of the function should just go here.

% systems
%
if ispc % Code is on Windows platform
    [~,systemview] = memory;
    availableRAM=systemview.PhysicalMemory.Available;
elseif isunix % Code is on Linux platform
    try
        availableRAM = double(py.psutil.virtual_memory().available);
    catch
        [~,freebytes] = system('python -c "import psutil; print(psutil.virtual_memory().available)"');
        availableRAM = str2double(freebytes);
    end
elseif ismac % Code is on Mac platform
    % basically the above one for Linux can be used for Mac as
    % well, just in case no python package psutil installed
    [~,out] = system('vm_stat | grep "Pages free"');
    mem = sscanf(out,'Pages free: %f.');
    availableRAM = mem*4096;
else
    disp('Platform not supported')
end

summary.availableRAM_GB=availableRAM/(1024^3);

summary.execution_duration=toc(summary.execution_duration);

if nargout==0
    fprintf('%s checkRAM: Available %.2f GB\n', datetime('now'),summary.availableRAM_GB);
elseif nargout==1
    varargout{1}=availableRAM;
elseif nargout==2
    varargout{1}=availableRAM;
    varargout{2}=summary;
else
    error('Wrong nubmer of output arguments')
end





end  %%% END CHECKRAM
