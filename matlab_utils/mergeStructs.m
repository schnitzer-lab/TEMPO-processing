function s_out = mergeStructs(structs)
    
    s_out = struct();
    for i_s = 1:numel(structs)
        fieldNames = fieldnames(structs{i_s});
        for i_f = 1:numel(fieldNames)
            field_name    = fieldNames{i_f};
            s_out.(field_name) = structs{i_s}.(field_name);
        end
    end
end