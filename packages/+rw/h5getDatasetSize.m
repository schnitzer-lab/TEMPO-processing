function varargout = h5getDatasetSize(filepath, datasetname, dim)
   
    if(nargin < 3)
        dim=[];
    end
    
    info = h5info(filepath, datasetname);
    
    sizes = info.Dataspace.Size;
    
    if(~isempty(dim)), sizes = sizes(dim); end
    varargout = num2cell(sizes);
end
