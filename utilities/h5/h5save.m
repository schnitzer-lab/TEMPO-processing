function [info] = h5save(fname, data, dspath, varargin)
% Save a Matlab struct/array into an HDF5 file
%   adapted from the EasyH5 Toolbox: https://github.com/fangq/easyh5
%
% SYNTAX:
% h5save(fname, data);
% h5save(fname, data, datasetpath);
%
% INPUTS:
% - fname - h5 filename
% - data  - a structure/cell/Class object to be stored
% - datasetpath - path to a dataset where you want to store data e.g.
% 'movie'
%
% OUTPUTS:
% - the latest h5info of this file
%
% OPTIONS:
% - 'dspath': the dataset path for storing the variable. If not given, the 
%               actual variable name for the data input will be used as
%               the root object. The value shall not include '/'.
%
% HISTORY
% - 2020-06-01 16:32:40 - created by Jizhou Li (hijizhou@gmail.com)
% - 2020-06-02 18:52:10 - add datatype handling
% - 2020-06-04 16:00:37 - dataset as a 3rd argument, changed syntax and organization of the function - Radek Chrapkiewicz
% - 2020-06-28 02:41:00 - Handling existing datasets by h5write RC
% - 2021-04-23 16:48:00 - Updated handling of existing non-numeric datasets
% and overall logic a bit (VK)
% - 2026-08-26 refactored, to be able so save multidimentional datasets (VK)

%% VARIABLE CHECK 

if(nargin<2)
    error('you must provide at least two inputs');
end

if nargin < 3
    dspath=inputname(2);
end

if ~dspath(1)~='/'
   dspath=['/' dspath];
end
%% CORE

% check whether this dataset path has been used
dspath_exists = rw.h5checkDatasetExists(fname, dspath);   

if(dspath_exists), warning('Dataset %s already exists, will attemt to overwrite',dspath); end

if (~dspath_exists && isnumeric(data) && isreal(data))

    h5create(fname, dspath, size(data),'Datatype', class(data));
    h5write(fname, dspath, data); 

else %matlab H5 writing for arbitrary data by Jizhou
    %data=jdataencode(data,'Base64',0,'UseArrayZipSize',0,options);
    try
        if(isa(fname,'H5ML.id'))
            fid=fname;
        else
            if isfile(fname)
                fid = H5F.open(fname, 'H5F_ACC_RDWR','H5P_DEFAULT');
            else
                fid = H5F.create(fname, 'H5F_ACC_TRUNC', H5P.create('H5P_FILE_CREATE'), H5P.create('H5P_FILE_ACCESS'));
            end
        end
        
        if(dspath_exists)
           H5L.delete(fid, dspath,'H5P_DEFAULT');
           warning("dspath %s was overwritten, but allocated memory wasn't"+ ...
                   " released. Use h5repack to free it.", dspath);
        end

        options.compression='';
        options.compresslevel=0;
        options.compressarraysize=100;
        options.unpackhex=1;
        options.dotranspose = 0;
        options.skipempty=true;
        obj2h5(dspath,data,fid,1, options);
    catch ME
        if(exist('fid','var') && fid>0), H5F.close(fid); end
        rethrow(ME);
    end

    H5F.close(fid);
end

info = h5info(fname);
end
