function [T] = preProcessSessionData(varargin)
%PREPROCESSSESSIONDATA take SessionData, a conversion cell array and trial
%start times as synchronised to an electrophysiology device. Return a table
%including data in a format ready for analysis
%
% Input:
%   ephysTrialStartTime: numeric, ephys start times
%   idxephysTrialStartTime: numeric integer or logical, the index within
%       the SessionData which are included in the ephysData
%   dataFile: struct, file location or nothing, which brings up gui. See
%       trials2table for more info
%   conversionFile: cell, file location or nothing, which brings up gui. 
%       See trials2table for more info
%   byPass: Specific to protocol Conversion_Click2AFCRewPulsSingle_nTrials.
%       Once manually checked, the check to ensure left and right reward 
%       delay can be by passed, taking only the right reward delay values.

% set defaults
defaultDatafile = [];
defaultConversionFile = [];
defaultephysIdx = [];
defaultByPass = false;

isFileLoc = @(x) ischar(x) || isstring(x) || iscellstr(x);
validConversionArrayOrFile = @(x) isFileLoc(x) ||...
    (iscell(x) && size(x, 2) == 3) || isempty(x) ;
validStructOrFile = @(x) isFileLoc(x) ||...
    isstruct(x) || isempty(x);
validNumeric =  @(x) validateattributes(x, {'numeric'}, {});
validIdx = @(x) validateattributes(x, {'logical', 'numeric'},...
    {'integer'});
validLogical = @(x) validateattributes(x, {'logical'}, {'scalar'});

p = inputParser;
addRequired(p, 'ephysTrialStartTime', validNumeric);
addOptional(p, 'idxephysTrialStartTime', defaultephysIdx, validIdx);
addParameter(p, 'dataFile', defaultDatafile, validStructOrFile);
addParameter(p, 'conversionFile', defaultConversionFile,...
    validConversionArrayOrFile);
addParameter(p, 'byPass', defaultByPass, validLogical);
parse(p, varargin{:});

data = p.Results.dataFile;
conversionFile = p.Results.conversionFile;
ephysTrialStartTime = p.Results.ephysTrialStartTime;
idxephysTrialStartTime = p.Results.idxephysTrialStartTime;
byPass = p.Results.byPass;

clear p

if isempty(idxephysTrialStartTime)
    idxephysTrialStartTime = 1:data.nTrials;
end

% if no input, select files with gui
if ~isstruct(data) && isempty(data)
    [filename, pathname] = uigetfile('*.mat',...
        'Choose Session to Analyse', 'multiselect', 'off');
    % stop if user cancels
    if isequal(filename, 0)
        disp('User selected cancel')
        return;
    end
    data = [pathname, filename];
end

if isFileLoc(data) % if input is file location
    data = load(data);
    data = data.(subsref(fieldnames(data), substruct('{}',{1}))); % unwrap
    assert(isstruct(data), 'The data file for trials must be a struct')
end

%%

% trials2table handles loading the conversionFIle
T = trials2table('dataFile', data, 'conversionFile', conversionFile);
T = combineTrialConditions(T);
T = extractRawData(data, T);
T.ephysTrialStartTime = NaN(data.nTrials, 1);
T.ephysTrialStartTime(idxephysTrialStartTime) = ephysTrialStartTime;

% correction for differences in protocol min, max and exponent reward delay

if isequal(conversionFile, 'Conversion_Click2AFCRewPulsSingle_nTrials')
    if isequal(T.exponentRewardDelayLeft,...
               T.exponentRewardDelayRight)...
       && isequal(T.exponentRewardDelayLeft,...
                  T.exponentRewardDelayRight) || byPass
      T.minimumRewardDelay  = T.minimumRewardDelayRight;
      T.maximumRewardDelay  = T.maximumRewardDelayRight;
      T.exponentRewardDelay = T.exponentRewardDelayRight;
      T = removevars(T, {'minimumRewardDelayRight',...
                         'maximumRewardDelayRight',...
                         'maximumRewardDelayLeft',...
                         'exponentRewardDelayRight',...
                         'exponentRewardDelayLeft'});
    else
        error(['There is a missmatch between the left and right reward'...
            'delays. Please check the data.'])
    end
end
end