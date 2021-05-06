function [matchIdx, isInShortVec] = matchElements(vecA, vecB)
% MATCHELEMENTS takes two vectors of different lengths. It retruns which
% elements of the longer vector are present in the short vector
% (isInShortVec) and, for each elemnt of the short vector, the index for
% where it can be found in the long vector.

validateattributes(vecA, {'numeric'}, {'vector'});
validateattributes(vecB, {'numeric'}, {'vector'});

if length(vecA) > length(vecB)
   longVec = vecA;
   shrtVec = vecB;
else
   longVec = vecB;
   shrtVec = vecA;
end

matchIdx = NaN(length(shrtVec), 1);
isInShortVec = zeros(length(longVec), 1);
j=1;

for i = 1:length(longVec)
    isInShortVec(i) = isequal(longVec(i), shrtVec(j));
    if isInShortVec(i) == 1
        matchIdx(j) = i;
        if j == length(shrtVec)
            return
        end
        j = j + 1;
    end
end

end