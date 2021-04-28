function [T] = parseIntanSessionData(recordingDir, eventData)
%% Function to load Bpod Data with Intan event times from recording folder
% recordingDir full path to a directory containing recording data
% eventData is a struct with fields 'type' & 'time' describing bpod events 

%% Parse input

if nargin < 1
    recordingDir = pwd;
end

if istable(recordingDir) % assume directly passed the session data
    Combined.ConfidenceSessionData = recordingDir;
else % load the data
    [~, recordingData] = parseRecPath(recordingDir);
    assert(~isempty(recordingData.CombinedRecData),...
    'Couldn''t find combined session data in recording directory');
    % load Combined Data
    load([recordingData.CombinedRecData.folder filesep ...
        recordingData.CombinedRecData.name],'Combined')
end
% Convert Bpod Session Data to table
T = trials2table('dataFile',Combined.ConfidenceSessionData,...
        'conversionFile','Conversion_Slim2.mat');
    
% Add trial desciptions
T = combineTrialConditions(T);

% Get Trial event times
T = extractRawData(Combined.ConfidenceSessionData, T);

% Sync the bpod and Intan trial stats if needed
if ~any(strcmpi(T.Properties.VariableNames,...
        'ephysTrialStartTime'))
    T = syncIntanSessionData(T,eventData);        
end    




end % parseIntanSessionData function