function inserted = insertVec(toInsert, vector, index)
% INSERT
%
% inserted = insert(toInsert, vector, location) insert a scalar or vector
%   'toInsert' into another vector 'vector' at the index 'index'. If there
%   are several indexes, loop through them all, inserteing toInsert at each
%   index. If the length of toInsert matches the length of index, each
%   element of toInsert, is inserted at the index of the corresponding 
%   element in index

validateattributes(toInsert, {'numeric'}, {'vector'})
validateattributes(vector, {'numeric'}, {'vector'})
validateattributes(index, {'numeric'}, {'vector', 'integer'})

vector = vector(:);
toInsert = toInsert(:);

if length(index) == length(toInsert)
    inserted = cat(1,...
                vector(1 : index(1) - 1),...
                toInsert(1),...
                vector(index(1) : end));
   if isvector(index)
        for i = 2 : length(index)
            inserted = cat(1,...
                        inserted(1 : index(i) -1),...
                        toInsert(i),...
                        inserted(index(i) : end));
        end   
   end
else
    inserted = cat(1,...
                vector(1 : index(1) - 1),...
                toInsert,...
                vector(index(1) : end));
    if isvector(index)
        for i = 2 : length(index)
            inserted = cat(1,...
                        inserted(1:index(i) - 1),...
                        toInsert,...
                        inserted(index(i) : end));
        end
    end
end