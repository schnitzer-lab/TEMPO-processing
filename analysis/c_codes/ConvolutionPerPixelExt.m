% ConvolutionPerPixelExt - Calls external routine for per-pixel convolution with given filter file
%
% SYNTAX:
% [status,cmdout,summary]=MultitaperPerPixelExt(fullpath_in, fullfilterpath,fullpath_out) - use with default options
% [status,cmdout,summary]=MultitaperPerPixelExt(fullpath_in,fullpath_out,'option1')
%
% INPUTS:
% - fullpath_in  - full path(!) of the input h5 file
% - fullfilterpath - full paths (!) to the file with filter (1-column file)
% - fullpath_out - full path(!) of the  output h5 file. The existing file
% will be overritten
% - options - described below
%
% OUTPUTS:
% - outputs - system call outputs and summary
%
% OPTIONS:
%   verbose (1) . Not yet supported by the external routine.
%   cmd (false) - run processing in external cmd window. 
%        Note that summary.execution_duration is inaccurate in that case.
%   num_cores (1) - number of OpenMP threads to use.
%   dataset ('/movie') - the name of the movie dataset in the input h5 file.
%   exepath ('../analysis/compiled/hdf5_movie_convolution/x64/Release/hdf5_movie_convolution.exe') -
%       paths to the external routine;
%   hdfversioncheck (2) - controls HDF5_DISABLE_VERSION_CHECK, see
%      support.hdfgroup.org/HDF5/doc/H5.user/Environment.html for details
%   optimize_flag ('--avx') - use optimized vector instruction set. Can be
%   '', '--sse' and '--avx'
% 
% DETAILED HELP:
% Calls external compiled file (C++ program that relies on  eigen 
% and HighFive HDF5 libraries, as well as convolution code using vectorized 
% instuctions from https://gist.github.com/vermorel/7ad35212df44f3a79bca8ab5fe8e7622)
% For futher details check "hdf5_movie_convolution.exe --help"
%
% DEMO:
% ConvolutionPerPixelExt(fullpath, filterpath, outpath, 'num_cores', 12);;
%
% ISSUES
% #1 - options.verbose does not affct the output of the external routine

function [status,cmdout,summary]=ConvolutionPerPixelExt(fullpath_in,...
    fullfilterpath, fullpath_out, varargin)
%% options
    options = DefaultOptions();
    if nargin>=3
        options=getOptions(options,varargin);
    end

    execution_started = datetime('now');
    execution_started_tic = tic();
%% CORE
    if (exist(fullpath_out, 'file') == 2) 
        if(options.delete) 
            warning("output file " + fullpath_out + " already exists, deleting first");
            delete(fullpath_out);
        else    
            error("output file " + fullpath_out + " already exists");
        end
    end
    if (~exist(fileparts(fullpath_out), 'dir')) mkdir(fileparts(fullpath_out)); end
    
    remove_mean_flag = '';
    if(options.remove_mean) remove_mean_flag = '--remove_mean'; end
    
    if(options.cmd ) 
       start_command = ['start ' options.exepath];
    else    
       start_command = ['"' options.exepath '"'];
    end

    cmd_call = ['set HDF5_DISABLE_VERSION_CHECK=' num2str(options.hdfversioncheck) ...
                ' & ' start_command ' -i ' fullpath_in ' -d ' options.dataset ...
                ' -f ' fullfilterpath ' -o ' fullpath_out ' --dataset_out ' options.dataset ...
                ' -t ' num2str(options.num_cores) ' ' remove_mean_flag ' ' options.optimize_flag ];

    [status,cmdout] = system(cmd_call,'-echo');
    if(status) error("external routine failed"); end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function options =  DefaultOptions()
    options.verbose=1;
    
    options.delete=false;
    
    options.exepath='../analysis/compiled/hdf5_movie_convolution/x64/Release/hdf5_movie_convolution.exe';
    options.hdfversioncheck = 2;
    options.num_cores = 1;
    options.dataset = '/mov';
    options.remove_mean = false;
    options.optimize_flag = '--avx';
    options.cmd = false;
end

