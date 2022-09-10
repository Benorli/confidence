function [y, e] = discretizeEqualParts(x, n)
% y = DISCRETIZEEQUALPARTS(x, n)
%
% y = discretizeEqualParts(x, n) discretizes x into bins with equal numbers
%   of elements in each bin
%
% input: x: numeric vector
%        n: scalar integer
%
% output: y: Bin identity for each element of x (double)
%         e: Bin edges (double) size n + 1

validateattributes(x, {'numeric'}, {'vector'});
validateattributes(n, {'numeric'}, {'integer', 'scalar',...
    '>', 1....
    '<', numel(x)})

if n == 2
    edges = [min(x), quantile(x, 0.5) max(x)];
else
    edges = [min(x), quantile(x, n - 1) max(x)];
end

[y, e] = discretize(x, edges);

end
