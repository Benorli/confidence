function [peakNearestDrop, changeIdxs] = findPeakNearestDrop(instFR, timePoints, varargin)
%% FINDPEAKNEARESTDROP Finds the peak time slosest the most steep drop in 
% time series data.
% 
% [peakNearestDrop] = findPeakNearestDrop(instFR, binCenters) takes a
%   2d matrix instFR of instantanious firing rate, with each row  
%   representing a trial and each column representing a time point. It also 
%   takes timePoints a vector of time points associated with instFR. The
%   output peakNearestDrop is the time at which the peak nearest the
%   steepest drop in the value of instFR.
%
% Optional inputs:
% maxNumChanges: A scalar defining the number of change points to detect.
%                The default value is 5. See the function ischange for more 
%                details.

narginchk(2,3);

validateattributes(instFR, {'numeric'}, {'2d'});
validateattributes(timePoints, {'numeric'}, {'vector'});

if ~isempty(varargin)
    maxNumChanges = varargin{1};
    validateattributes(maxNumChanges, {'numeric'}, {'scalar'});
else % default maxNumChanges
    maxNumChanges = 5;
end

[~, segmentSlope, ~] = ischange(instFR, 'linear', 2,...
                                'MaxNumChanges', maxNumChanges,...
                                'SamplePoints', timePoints);
maxIndices = islocalmax(instFR, 2,...
                        'MinSeparation', 10,...
                        'SamplePoints', timePoints);
         
% define fixed size for loop  
nTrials = size(instFR, 1); 
idxPeakNearestChange  = zeros(nTrials, 1);
peakNearestDrop = zeros(nTrials, 1);
changeIdxs = zeros(nTrials, 1);

for i = 1 : size(instFR, 1) % for every row
    
    trlSegSlope = segmentSlope(i, :);
    % find the start and end idx of the most negative slope
    strNegSlope   = find(min(trlSegSlope) == trlSegSlope, 1);
    endNegSlope   = find(min(trlSegSlope) == trlSegSlope, 1, 'last');
    % get the idx of the average
    changeIdxs(i) = round(mean([strNegSlope, endNegSlope]));
    
    % get time of idx
    trlMaxTimes    = timePoints(maxIndices(i, :));
    trlChangeTimes = timePoints(changeIdxs(i));
    
    % find the closest local max to the change idx
    [~, idxPeakNearestChange(i)] = min(abs(trlMaxTimes - trlChangeTimes));
    peakNearestDrop(i) = trlMaxTimes(idxPeakNearestChange(i));
end
end