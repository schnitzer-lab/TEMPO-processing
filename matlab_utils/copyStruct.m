function T = copyStruct(S, fieldList)
    if nargin == 1
       fieldList = fieldnames(S);
    end 
    for iField = 1:numel(fieldList)
       field    = fieldList{iField};
       T.(field) = S.(field);
    end
end