function [bpodIdxEphysTrialStart, bestMatchIdx, bestMatchVal] = synchTrialStarts(varargin)
% SYNCHTRIALSTARTS() takes bpod and ephys trial start times and determines
% the optimal alignment. It returns the index for ephysstart times to be
% matched to Bpod start times. It does this based on trial starts diffs.
% 
%   [ephysTrialStartTime] = synchTrialStarts(bpodTrialStart, ephysTrialStart,
%                           'PlotMatch', 1)
% 
% Example: Try switching the order of the inputs to understant how ouptut is given:
%           [bpodIdxEphysTrialStart, bestMatchIdx, bestMatchVal] =...
%           synchTrialStarts([1,2,3,6,8,10,15,20], 1:2:6)

%% parse variable input arguments

p = inputParser; % Create object of class 'inputParser'

% define defaults
defPlotMatch = 1;

% validation funs
valNumNonEmpty = @(x) validateattributes(x, {'numeric'},...
    {'nonempty'});
valBinaryScalar = @(x) validateattributes(x, {'logical', 'numeric'},...
    {'nonempty', 'binary', 'scalar'});

addRequired(p, 'bpodTrialStart', valNumNonEmpty);
addRequired(p, 'ephysTrialStart', valNumNonEmpty);
addParameter(p, 'PlotMatch', defPlotMatch, valBinaryScalar);

parse(p, varargin{:});

bpodTrialStart  = p.Results.bpodTrialStart;
ephysTrialStart = p.Results.ephysTrialStart;
plotMatch       = p.Results.PlotMatch;

clear p

%% Slide through possible alignments

lengthDiff = abs(length(bpodTrialStart) - length(ephysTrialStart));
matchVal = NaN(lengthDiff, 1);

if length(bpodTrialStart) == length(ephysTrialStart)
    disp('Ephys and Bpod trial starts are the same length')
    bestMatchIdx = 1;
    bestMatchVal = sum(abs(diff(bpodTrialStart(:)) -...
        diff(ephysTrialStart(:))));
    bpodIdxEphysTrialStart = ephysTrialStart;
    return
elseif length(bpodTrialStart) > length(ephysTrialStart)
    disp('Ephys trial starts are matched to an index within Bpod trial starts')
    for i = 1 : lengthDiff
        tempBpodTS = bpodTrialStart(i : i + length(ephysTrialStart) -1);
        matchVal(i) = sum(abs(diff(tempBpodTS(:)) -...
            diff(ephysTrialStart(:))));
    end
    % Output mus be ephys times, indexed to Bpod times
    [bestMatchVal, bestMatchIdx] = min(matchVal);
    bpodIdxEphysTrialStart = NaN(length(bpodTrialStart), 1); 
    bpodIdxEphysTrialStart(bestMatchIdx : bestMatchIdx +...
        length(ephysTrialStart) - 1) = ephysTrialStart;
elseif length(bpodTrialStart) < length(ephysTrialStart)
    disp('Ephys trial starts are cut to index match with Bpod trial starts')
    for i = 1 : lengthDiff
        tempEphysTS = ephysTrialStart(i : i + length(bpodTrialStart) -1);
        matchVal(i) = sum(abs(diff(bpodTrialStart(:))-diff(tempEphysTS(:))));
    end
    % Output mus be ephys times, indexed to Bpod times
    [bestMatchVal, bestMatchIdx] = min(matchVal);
    bpodIdxEphysTrialStart = ephysTrialStart(bestMatchIdx : bestMatchIdx +...
        min([lengthDiff, length(bpodTrialStart)]) - 1);
end


if plotMatch
    plot(matchVal)
    xlabel('Trial shift')
    ylabel('Match quality (lower value, better match)')
    fprintf('Best matched 1st trial: %d \n', bestMatchIdx)
    fprintf('Best match value: %d \n', min(bestMatchVal))
    box off
end
    
end