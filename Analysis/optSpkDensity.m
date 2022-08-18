function [spkDensity, sigma, windowedSpks, binnedSpks, binCenters] =...
    optSpkDensity(spks, events, post, prev, binSize, resolution, varargin)
% OPTSPKDENSITY return spike density, by convolution with a gassian kernel
% which has a sigma defined by a sskernel (Shimazaki and Shinomoto et al
% 2010)
%
%   optSpkDensity(spks, events, post, prev, resolution) where spks is a
%   vector of spike times, events is a vector of event times, post is a
%   scalar times in ms, prev is a scalar  time in ms and the resolution
%   in a scalar representing the resolution of time used for smoothing.
%   Optional logical input, determines if output is wrapped in cell.

narginchk(6, 7);

validateattributes(post, {'numeric'}, {'vector'});
validateattributes(post, {'numeric'}, {'vector'});
validateattributes(post, {'numeric'}, {'scalar'});
validateattributes(prev, {'numeric'}, {'scalar'});
validateattributes(binSize, {'numeric'}, {'scalar'});
validateattributes(resolution, {'numeric'}, {'scalar'});
if ~isempty(varargin)
    validateattributes(varargin{1}, {'logical', 'numeric'},...
        {'binary', 'scalar'});
end

windowedSpks = compareSpikes2EventsMex(spks, events,...
    'Post',        post,...
    'Previous',    prev);
% fit sigma for gaussian kernel
t = linspace(-prev, post, resolution);
superimposedSpks = cell2mat(windowedSpks);
[~, ~, sigma] = sskernel(superimposedSpks,  t);

% bin spikes (into single spike bins) for convolution
[binnedSpks, binCenters] = binSpikesPerEventMex(spks, events,...
    'Post',     post,...
    'Previous', prev,...
    'BinSize',  binSize,...
    'Hz',       false);

binnedSpks = reshape(cell2mat(binnedSpks), length(binCenters),...
    length(binnedSpks))';

% define kernel
resBinSize = round((post + prev) / resolution);
normDist = normpdf(-4 * sigma : resBinSize : 4 * sigma, 0, sigma);

% convolve
% To get results in Hz, divide by binsize in seconds
resBinSizeSecond = resBinSize / 1000;
spkDensity = conv2(binnedSpks, normDist / resBinSizeSecond, 'same');

if ~isempty(varargin) && varargin{1} == true
    
    spkDensity   = {spkDensity};
    sigma        = {sigma};
    windowedSpks = {windowedSpks};
    binnedSpks   = {binnedSpks};
    binCenters   = {binCenters};
    
end

end