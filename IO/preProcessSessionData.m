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

% set defaults
defaultDatafile = [];
defaultConversionFile = [];
defaultephysIdx = [];

isFileLoc = @(x) ischar(x) || isstring(x) || iscellstr(x);
validConversionArrayOrFile = @(x) isFileLoc(x) ||...
    (iscell(x) && size(x, 2) == 3) || isempty(x) ;
validStructOrFile = @(x) isFileLoc(x) ||...
    isstruct(x) || isempty(x);
validNumeric =  @(x) validateattributes(x, {'numeric'}, {});
validIdx = @(x) validateattributes(x, {'logical', 'numeric'},...
    {'integer'});

p = inputParser;
addRequired(p, 'ephysTrialStartTime', validNumeric);
addOptional(p, 'idxephysTrialStartTime', defaultephysIdx, validIdx);
addParameter(p, 'dataFile', defaultDatafile, validStructOrFile);
addParameter(p, 'conversionFile', defaultConversionFile,...
    validConversionArrayOrFile);
parse(p, varargin{:});

data = p.Results.dataFile;
conversionFile = p.Results.conversionFile;
ephysTrialStartTime = p.Results.ephysTrialStartTime;
idxephysTrialStartTime = p.Results.idxephysTrialStartTime;

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

end