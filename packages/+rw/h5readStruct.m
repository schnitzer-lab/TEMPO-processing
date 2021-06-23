function result = h5readStruct(file_name, dataset_name)

    f_info = h5info(file_name, dataset_name);

    result = struct;
    if(~isempty(f_info.Datasets))
        for name_dataset = string({f_info.Datasets.Name})
            result.(name_dataset) = h5read(file_name, dataset_name + "/" + name_dataset);
        end
    end
    if(~isempty(f_info.Groups))
        for name_group = string({f_info.Groups.Name})
            split_name = strsplit(name_group, '/');
            result.(split_name(end)) = rw.h5readStruct(file_name, name_group);
        end
    end
end