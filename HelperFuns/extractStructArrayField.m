function data = extractStructArrayField(x, field, len)
% EXTRACTSTRUCTARRAYFIELD
%
%   data = extractStructArrayField(x, field, len) takes a field variable 
%          from each array index of a struct array and returns an array
%          containing only each value with that fieldname from the entire
%          structArray. len allows the ouput length to be set.

validateattributes(x, {'struct'}, {})
validateattributes(field, {'char', 'string'}, {})
validateattributes(len, {'int', 'double'}, {'scalar'})

data = NaN(length(x), 1);
for i = 1:length(x)
data(i) =  x(i).(field);
end

data = data(:);
data = data(1:len);

end