% s = functionCallStruct(names)
%
% Creates a structure detailing the function from where it is called from.
%
% Inputs:
%    names: cell array of char strings. Variable names from the caller's
%           workspace to include in the structure (input parameters names)
%
% Outputs:
%    s: structure of a form {callFunctionName : {'callDateTimeAutomatic' : dateTimeString,
%       'callFilenameAutomatic' : filename, names{1} : value2, names{2} : value2, ...}
function s = functionCallStruct(names)

    var_s = struct();
    for name = names
        var_s.(name{:}) = evalin('caller', [name{:},';']);
    end

    stack = dbstack('-completenames');
    if( numel(stack) >= 2)
        callFunctionName = stack(2).name;
        var_s.('callFilenameAutomatic') = stack(2).file;
    else 
        callFunctionName = 'base';
        var_s.('callFilenameAutomatic') = '';
    end

    var_s.('callDateTimeAutomatic') = char(datetime());

    s = struct(callFunctionName, var_s);
end

