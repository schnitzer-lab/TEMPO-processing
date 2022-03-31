function h5writeStruct(h5filename, tosave, dataset_name)

%     info_cells = cell(length(fieldnames(tosave)),1);
    if(~isstruct(tosave))
        h5save(h5filename, tosave, char(dataset_name));
    else
        for dataset_name_new = string(fieldnames(tosave))'
            if(~rw.h5checkDatasetExists(h5filename, dataset_name))
                rw.h5writeStruct(h5filename, [0], [dataset_name, '/empty_spec'])
            end
            
            value = tosave.(dataset_name_new);
            rw.h5writeStruct(h5filename, value, dataset_name + "/" + dataset_name_new);
        end
    end
end