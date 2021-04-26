function [info] = h5save(fname, data, varargin)
% Save a Matlab struct/array into an HDF5 file
%   adapted from the EasyH5 Toolbox: https://github.com/fangq/easyh5
%
% SYNTAX:
% h5save(fname, data);
% h5save(fname, data, datasetpath);
% h5save(fname, data, datasetpath, 'Parameter',Value,...);
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
%
% ISSUES
% #1 - 
%
% TODO
% *1 - add execution time summary, also speed MB/s for further comparison
% (suggested by RC)
% *2 - Jizhou please explore if the compression level actually works, I
% would get rid of it (RC)


%% OPTIONS

options.compression='';
options.compresslevel=0;
options.compressarraysize=100;
options.unpackhex=1;
options.dotranspose = 0;
options.skipempty=true;

%% VARIABLE CHECK 

if(nargin<2)
    error('you must provide at least two inputs');
end

if nargin>=3
    dspath=varargin{1};
else
    dspath=inputname(2);
end

if nargin>=4
    options=getOptions(options,varargin(1:end)); % CHECK IF NUMBER OF THE OPTION ARGUMENT OK!
end

if ~dspath(1)~='/'
   dspath=['/' dspath];
end

%% CORE

% check whether this dataset path has been used
dspath_new = false;
try
    datasetdata=h5read(fname,dspath);
catch ME
    dspath_new = true;
end    
if ~dspath_new
    h5info(fname)
    try
        h5write(fname,dspath,data); % 2020-06-28 02:41:00 RC
        warning('Dataset %s already existed, and I overwrote it with h5write (RC)',dspath);
        info = h5info(fname);
        return;
    catch 
        error('The dataset path has been used, choose another one!');
    end
end

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
    obj2h5(dspath,data,fid,1,options);
catch ME
    if(exist('fid','var') && fid>0)
        H5F.close(fid);
    end
    rethrow(ME);
end

if(~isa(fname,'H5ML.id'))
    H5F.close(fid);
end

info = h5info(fname);

end
%%-------------------------------------------------------------------------
function oid=obj2h5(name, item,handle,level,varargin)
% make things simplier, converting everything into binary
%oid=any2h5(name,item,handle,level,varargin{:});


if(iscell(item))
    oid=cell2h5(name,item,handle,level,varargin{:});
elseif(isstruct(item))
    oid=struct2h5(name,item,handle,level,varargin{:});
elseif(ischar(item) || isa(item,'string'))
    oid=mat2h5(name,item,handle,level,varargin{:});
elseif(isa(item,'containers.Map'))
    oid=map2h5(name,item,handle,level,varargin{:});
elseif(isa(item,'categorical'))
    oid=cell2h5(name,cellstr(item),handle,level,varargin{:});
elseif(islogical(item) || isnumeric(item))
    oid=mat2h5(name,item,handle,level,varargin{:});
else
    oid=any2h5(name,item,handle,level,varargin{:});
end

end

%%-------------------------------------------------------------------------
function oid=idxobj2h5(name, idx, varargin)
oid=obj2h5(sprintf('%s%d',name,idx), varargin{:});
end
%%-------------------------------------------------------------------------
function oid=cell2h5(name, item,handle,level,varargin)

num=numel(item);
if(num>1)
    idx=reshape(1:num,size(item));
    idx=num2cell(idx);
    oid=cellfun(@(x,id) idxobj2h5(name, id, x, handle,level,varargin{:}), item, idx, 'UniformOutput',false);
else
    oid=cellfun(@(x) obj2h5(name, x, handle,level,varargin{:}), item, 'UniformOutput',false);
end
end
%%-------------------------------------------------------------------------
function oid=struct2h5(name, item,handle,level,varargin)

num=numel(item);
if(num>1)
    oid=obj2h5(name, num2cell(item),handle,level,varargin{:});
else
    pd = 'H5P_DEFAULT';
    gcpl = H5P.create('H5P_GROUP_CREATE');
    tracked = H5ML.get_constant_value('H5P_CRT_ORDER_TRACKED');
    indexed = H5ML.get_constant_value('H5P_CRT_ORDER_INDEXED');
    order = bitor(tracked,indexed);
    H5P.set_link_creation_order(gcpl,order);
    if(varargin{1}.unpackhex)
        name=decodevarname(name);
    end
    try
        handle=H5G.create(handle, name, pd,gcpl,pd);
        isnew=1;
    catch
        isnew=0;
    end

    names=fieldnames(item);
    oid=cell(1,length(names));
    for i=1:length(names)
        oid{i}=obj2h5(names{i},item.(names{i}),handle,level+1,varargin{:});
    end
    
    if(isnew)
        H5G.close(handle);
    end
end

end
%%-------------------------------------------------------------------------
function oid=map2h5(name, item,handle,level,varargin)

pd = 'H5P_DEFAULT';
gcpl = H5P.create('H5P_GROUP_CREATE');
tracked = H5ML.get_constant_value('H5P_CRT_ORDER_TRACKED');
indexed = H5ML.get_constant_value('H5P_CRT_ORDER_INDEXED');
order = bitor(tracked,indexed);
H5P.set_link_creation_order(gcpl,order);
try
    if(varargin{1}.unpackhex)
        name=decodevarname(name);
    end
    handle=H5G.create(handle, name, pd,gcpl,pd);
    isnew=1;
catch
    isnew=0;
end

names=item.keys;
oid=zeros(length(names));
for i=1:length(names)
    oid(i)=obj2h5(names{i},item(names{i}),handle,level+1,varargin{:});
end

if(isnew)
    H5G.close(handle);
end

end
%%-------------------------------------------------------------------------
function oid=mat2h5(name, item,handle,level,varargin)
if(isa(item,'string'))
    item=char(item);
end
typemap=h5types;

opt=varargin{1};
if(opt.dotranspose)
    item=permute(item, ndims(item):-1:1);
end

pd = 'H5P_DEFAULT';
gcpl = H5P.create('H5P_GROUP_CREATE');
tracked = H5ML.get_constant_value('H5P_CRT_ORDER_TRACKED');
indexed = H5ML.get_constant_value('H5P_CRT_ORDER_INDEXED');
order = bitor(tracked,indexed);
H5P.set_link_creation_order(gcpl,order);

if(~(isfield(opt,'complexformat') && iscellstr(opt.complexformat) && numel(opt.complexformat)==2) || strcmp(opt.complexformat{1},opt.complexformat{2}))
    opt.complexformat={'Real','Imag'};
end

usefilter=opt.compression;
complevel=opt.compresslevel;
minsize=opt.compressarraysize;
chunksize=jsonopt('Chunk',size(item),opt);

if(isa(item,'logical'))
    item=uint8(item);
end

if(~isempty(usefilter) && numel(item)>=minsize)
    if(isnumeric(usefilter) && usefilter(1)==1)
        usefilter='deflate';
    end
    if(strcmpi(usefilter,'deflate'))
        pd = H5P.create('H5P_DATASET_CREATE');
        h5_chunk_dims = fliplr(chunksize);
        H5P.set_chunk(pd,h5_chunk_dims);
        H5P.set_deflate(pd,complevel);
    else
        error('Filter %s is unsupported',usefilter);
    end
end

if(opt.unpackhex)
    name=decodevarname(name);
end

oid=[];

if(isempty(item) && opt.skipempty)
    warning('The HDF5 library is older than v1.8.7, and can not save empty datasets. Skip saving "%s"',name);
    return;
end

if(isreal(item))
    if(issparse(item))
        idx=find(item);
        oid=sparse2h5(name,struct('Size',size(item),'SparseIndex',idx,'Real',item(idx)),handle,level,varargin{:});
    else
        oid=H5D.create(handle,name,H5T.copy(typemap.(class(item))),H5S.create_simple(ndims(item), fliplr(size(item)),fliplr(size(item))),pd);
        H5D.write(oid,'H5ML_DEFAULT','H5S_ALL','H5S_ALL','H5P_DEFAULT',item);
    end
else
    if(issparse(item))
        idx=find(item);
        oid=sparse2h5(name,struct('Size',size(item),'SparseIndex',idx,'Real',real(item(idx)),'Imag',imag(item(idx))),handle,level,varargin{:});
    else
        typeid=H5T.copy(typemap.(class(item)));
        elemsize=H5T.get_size(typeid);
        memtype = H5T.create ('H5T_COMPOUND', elemsize*2);
        H5T.insert (memtype,opt.complexformat{1}, 0, typeid);
        H5T.insert (memtype,opt.complexformat{2}, elemsize, typeid);
        oid=H5D.create(handle,name,memtype,H5S.create_simple(ndims(item), fliplr(size(item)),fliplr(size(item))),pd);
        H5D.write(oid,'H5ML_DEFAULT','H5S_ALL','H5S_ALL','H5P_DEFAULT',struct(opt.complexformat{1},real(item),opt.complexformat{2},imag(item)));
    end
end
if(~isempty(oid))
   H5D.close(oid);
end

end

%%-------------------------------------------------------------------------
function oid=sparse2h5(name, item,handle,level,varargin)

opt=varargin{1};

idx=item.SparseIndex;

if(isempty(idx) && opt.skipempty)
    warning('The HDF5 library is older than v1.8.7, and can not save empty datasets. Skip saving "%s"',name);
    oid=[];
    return;
end

adata=item.Size;
item=rmfield(item,'Size');
hasimag=isfield(item,'Imag');

typemap=h5types;

pd = 'H5P_DEFAULT';


usefilter=opt.compression;
complevel=opt.compresslevel;
minsize=opt.compressarraysize;
chunksize=jsonopt('Chunk',size(item),opt);

if(~isempty(usefilter) && numel(idx)>=minsize)
    if(isnumeric(usefilter) && usefilter(1)==1)
        usefilter='deflate';
    end
    if(strcmpi(usefilter,'deflate'))
        pd = H5P.create('H5P_DATASET_CREATE');
        h5_chunk_dims = fliplr(chunksize);
        H5P.set_chunk(pd,h5_chunk_dims);
        H5P.set_deflate(pd,complevel);
    else
        error('Filter %s is unsupported',usefilter);
    end
end

idxtypeid=H5T.copy(typemap.(class(idx)));
idxelemsize=H5T.get_size(idxtypeid);
datatypeid=H5T.copy(typemap.(class(item.Real)));
dataelemsize=H5T.get_size(datatypeid);
memtype = H5T.create ('H5T_COMPOUND', idxelemsize+dataelemsize*(1+hasimag));
H5T.insert (memtype,'SparseIndex', 0, idxtypeid);
H5T.insert (memtype,'Real', idxelemsize, datatypeid);
if(hasimag)
    H5T.insert (memtype,'Imag', idxelemsize+dataelemsize, datatypeid);
end
oid=H5D.create(handle,name,memtype,H5S.create_simple(ndims(idx), fliplr(size(idx)),fliplr(size(idx))),pd);
H5D.write(oid,'H5ML_DEFAULT','H5S_ALL','H5S_ALL','H5P_DEFAULT',item);

space_id=H5S.create_simple(ndims(adata), fliplr(size(adata)),fliplr(size(adata)));
attr_size = H5A.create(oid,'SparseArraySize',H5T.copy('H5T_NATIVE_DOUBLE'),space_id,H5P.create('H5P_ATTRIBUTE_CREATE'));
H5A.write(attr_size,'H5ML_DEFAULT',adata);
H5A.close(attr_size);
end

function oid=any2h5(name, item,handle,level,varargin)
pd = 'H5P_DEFAULT';

if(varargin{1}.unpackhex)
    name=decodevarname(name);
end

rawdata=getByteStreamFromArray(item);  % use undocumented matlab function
oid=H5D.create(handle,name,H5T.copy('H5T_STD_U8LE'),H5S.create_simple(ndims(rawdata), size(rawdata),size(rawdata)),pd);
H5D.write(oid,'H5ML_DEFAULT','H5S_ALL','H5S_ALL',pd,rawdata);

adata=class(item);
space_id=H5S.create_simple(ndims(adata), size(adata),size(adata));
attr_type = H5A.create(oid,'MATLABObjectClass',H5T.copy('H5T_C_S1'),space_id,H5P.create('H5P_ATTRIBUTE_CREATE'));
H5A.write(attr_type,'H5ML_DEFAULT',adata);
H5A.close(attr_type);

adata=size(item);
space_id=H5S.create_simple(ndims(adata), size(adata),size(adata));
attr_size = H5A.create(oid,'MATLABObjectSize',H5T.copy('H5T_NATIVE_DOUBLE'),space_id,H5P.create('H5P_ATTRIBUTE_CREATE'));
H5A.write(attr_size,'H5ML_DEFAULT',adata);
H5A.close(attr_size);

H5D.close(oid);
end


function newname = decodevarname(name,varargin)
%
%    newname = decodevarname(name)
%
%    Decode a hex-encoded variable name (from encodevarname) and restore
%    its original form
%
%    This function is sensitive to the default charset
%    settings in MATLAB, please call feature('DefaultCharacterSet','utf8')
%    to set the encoding to UTF-8 before calling this function.
%
%    author: Qianqian Fang (q.fang <at> neu.edu)
%
%    input:
%        name: a string output from encodevarname, which converts the leading non-ascii
%              letter into "x0xHH_" and non-ascii letters into "_0xHH_"
%              format, where hex key HH stores the ascii (or Unicode) value
%              of the character.
%              
%    output:
%        newname: the restored original string
%
%    example:
%        decodevarname('x0x5F_a')   % returns _a
%        decodevarname('a_')   % returns a_ as it is a valid variable name
%        decodevarname('x0xE58F98__0xE9878F_')  % returns 'å?˜é‡?' 
%
%    this file is part of EasyH5 Toolbox: https://github.com/fangq/easyh5
%
%    License: GPLv3 or 3-clause BSD license, see https://github.com/fangq/easyh5 for details
%

newname=name;
isunpack=1;
if(nargin==2 && ~isstruct(varargin{1}))
    isunpack=varargin{1};
elseif(nargin>1)
    isunpack=jsonopt('UnpackHex',1,varargin{:});
end

if(isunpack)
    if(isempty(regexp(name,'0x([0-9a-fA-F]+)_','once')))
        return
    end
    if(exist('native2unicode','builtin'))
        h2u=@hex2unicode;
        newname=regexprep(name,'(^x|_){1}0x([0-9a-fA-F]+)_','${h2u($2)}');
    else
        pos=regexp(name,'(^x|_){1}0x([0-9a-fA-F]+)_','start');
        pend=regexp(name,'(^x|_){1}0x([0-9a-fA-F]+)_','end');
        if(isempty(pos))
            return;
        end
        str0=name;
        pos0=[0 pend(:)' length(name)];
        newname='';
        for i=1:length(pos)
            newname=[newname str0(pos0(i)+1:pos(i)-1) char(hex2dec(str0(pos(i)+3:pend(i)-1)))];
        end
        if(pos(end)~=length(name))
            newname=[newname str0(pos0(end-1)+1:pos0(end))];
        end
    end
end

end

%--------------------------------------------------------------------------
function str=hex2unicode(hexstr)
val=hex2dec(hexstr);
id=histc(val,[0 2^8 2^16 2^32 2^64]);
type={'uint8','uint16','uint32','uint64'};
bytes=typecast(cast(val,type{id~=0}),'uint8');
str=native2unicode(fliplr(bytes(:,1:find(bytes,1,'last'))));

end

function typemap=h5types
typemap.char='H5T_C_S1';
typemap.string='H5T_C_S1';
typemap.double='H5T_IEEE_F64LE';
typemap.single='H5T_IEEE_F32LE';
typemap.logical='H5T_STD_U8LE';
typemap.uint8='H5T_STD_U8LE';
typemap.int8='H5T_STD_I8LE';
typemap.uint16='H5T_STD_U16LE';
typemap.int16='H5T_STD_I16LE';
typemap.uint32='H5T_STD_U32LE';
typemap.int32='H5T_STD_I32LE';
typemap.uint64='H5T_STD_U64LE';
typemap.int64='H5T_STD_I64LE';
end

function val=jsonopt(key,default,varargin)
%
% val=jsonopt(key,default,optstruct)
%
% setting options based on a struct. The struct can be produced
% by varargin2struct from a list of 'param','value' pairs
%
% authors:Qianqian Fang (q.fang <at> neu.edu)
%
% input:
%      key: a string with which one look up a value from a struct
%      default: if the key does not exist, return default
%      optstruct: a struct where each sub-field is a key 
%
% output:
%      val: if key exists, val=optstruct.key; otherwise val=default
%
% license:
%     BSD or GPL version 3, see LICENSE_{BSD,GPLv3}.txt files for details
%
% -- this function is part of JSONLab toolbox (http://iso2mesh.sf.net/cgi-bin/index.cgi?jsonlab)
% 

val=default;
if(nargin<=2)
    return;
end
key0=lower(key);
opt=varargin{1};
if(isstruct(opt))
    if(isfield(opt,key0))
       val=opt.(key0);
    elseif(isfield(opt,key))
       val=opt.(key);
    end
end
end