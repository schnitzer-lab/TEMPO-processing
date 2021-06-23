function h5writeStruct(file_name, tosave, dataset_name)

%     info_cells = cell(length(fieldnames(tosave)),1);
    if(~isstruct(tosave))
        h5save(file_name, tosave, char(dataset_name));
    else
        for name_dataset = string(fieldnames(tosave))'
            value = tosave.(name_dataset);
            rw.h5writeStruct(file_name, value, dataset_name + "/" + name_dataset);
        end
    end
end