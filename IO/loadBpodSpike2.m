function [SessionData, spikes, spike2TrialStart] = loadBpodSpike2(name)
% LOADBPODSPIKE2(name)
%
%   [SessionData, spikes, spike2TrialStart] = LOADBPODSPIKE2(name)
%       takes a string name, with the name of the animal. It then
%       simplifies loading of the recorded SessionData struct, spikes, a 
%       vector of spike times (in Spike2 time) and spike2TrialStart, a
%       vector of trialStartTimes (in Spike2 time). Uses ui selection.

validateattributes(name, {'char'}, {})

load('pathStruct', 'pathStruct');

startDirectory = cd;

% Choose Protocol based on experimentor
if contains(name, 'BN')
   sessionLocation = pathStruct.ExperimentorsFromBase.BN;
elseif contains(name, 'ML')
   temp = dir([pathStruct.BaseAnimalFolder name filesep 'MATLAB' filesep 'Click2*']);
   if isempty(temp)
       error('Couldn''t find Bpod directory')
   end
   sessionLocation = [filesep 'MATLAB' filesep temp.name filesep 'Session Data']; 
else
    error('New experimentor, the file location is unknown')
end

% load Bpod SessionData
cd([pathStruct.BaseAnimalFolder, name, sessionLocation])
[SessionDataFile] = uigetfile('.mat', 'Choose SessionData file');
SessionData = load(SessionDataFile);
SessionData = SessionData.SessionData;

cd([pathStruct.BaseAnimalFolder, name, '\MATLAB\Spike2Matlab'])
[spike2Files] = uigetfile('.mat', 'Choose Spike2 files', 'MultiSelect',...
    'on');

% load Spike2 spikes and trial starts
assert(numel(spike2Files) == 2, ['Choose two files, one containing spikes,'...
    'the othe containing trial start times, these are exports from Spike2'])

if contains(spike2Files{1}, 'spike')
    spikesFile = spike2Files{1};
    spike2TrialStartFile = spike2Files{2};
else
    spike2TrialStartFile = spike2Files{1};
    spikesFile = spike2Files{2};
end

% load and extract times from structs, defining the names for output
spikes = load(spikesFile);
spikes = spikes.(subsref(fieldnames(spikes), substruct('{}',{1}))...
    ).times(:);

spike2TrialStart = load(spike2TrialStartFile);
spike2TrialStart = spike2TrialStart.(subsref(fieldnames(...
    spike2TrialStart) ,substruct('{}',{1}))).times(:);

cd(startDirectory)

end
