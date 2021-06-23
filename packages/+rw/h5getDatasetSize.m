function size = h5getDatasetSize(filepath, datasetname, dim)
   
    if(nargin < 3)
        dim=0;
    end
    
    info = h5info(filepath, datasetname);
    
    size = info.Dataspace.Size;
    
    if(dim) size = size(dim); end
end
