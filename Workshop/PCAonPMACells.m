function [scores,...
    eigenVecs,...
    eigenVals,...
    explained,...
    cID,...
    cIDeig,...
    binCenters] = PCAonPMACells(sessionNames, cellIDs)
%PCAONCELLS performs PCA on a list of cells
%   [scores, eigenVecs, eigenVals, ID] = PCAonPMACells(sessionNames, cellIDs)
%
% Asumes
% - behaviour and spike data file names and paths
% - params (see p to modify)
% - path exists to the following repos: 
%       - density_estimation
%       - confidence 
%       - optotagging 
%       - IntanTools 
%       - clusterPositions 
%       - spikes

% params
p.post = 8000; % ms
p.prev = 0; % ms
p.binSize = 100; % ms 
p.minWT = 1; 

validateattributes(sessionNames, {'cell', 'char', 'string'}, {'nonempty'});
validateattributes(cellIDs, {'numeric'}, {'integer'});

% paths
bTfull = load(['C:\Users\Ben\Documents\_work_bnathanson\' ...
    'Summary_Analysis\Projects\RampingCellProject\Data\' ...
    'CombinedJuxtaProbesBehaviour']);
bTfull = bTfull.T;

recPathBase = ['C:\Users\Ben\Documents\_work_bnathanson'...
    '\Animal\Silicon Probe Data\'];

if iscell(sessionNames)
    sessionNames = cellfun(@char, sessionNames, 'UniformOutput', false);
end

isIncludedTrial = ismember(bTfull.RatSession, sessionNames) &...
    bTfull.selfExit &...
    bTfull.waitingTime > p.minWT;

bT = bTfull(isIncludedTrial, :);
clear bTfull

bT.ephysWaitStr = bT.ephysTrialStartTime + bT.waitingStartTime;
bT.ephysWaitEnd = bT.ephysTrialStartTime + bT.trialEndTime;

bT.RatSession = setcats(bT.RatSession, sessionNames);
nTrialsPS = histcounts(bT.RatSession);
nCumSum = [0, cumsum(nTrialsPS)];
nTrials = sum(nTrialsPS);
nCells = length(cellIDs);

% prealocate
nBins = ceil(abs(p.post - p.prev) / p.binSize);
eigenVecs = zeros(nBins * nCells, nBins);
scores = zeros(nTrials, nBins);
eigenVals = zeros(nBins * nCells, 1);
explained = zeros(nBins * nCells, 1);
cID = strings(nTrials, 1);
cIDeig = strings(nBins * nCells, 1);


for i = 1 : nCells
    recPath = [recPathBase, bTName2RecName(sessionNames(i))];
    data = loadRecordingData(recPath, 'ClusterID', cellIDs(i));
    spkTimes = data.Clusters.Times;
    
    idxCellTrial = nCumSum(i) + 1 : nCumSum(i + 1);
    idxCellEig = nBins * (i-1) + 1 : nBins * i;
    
    [binnedSpikes, binCenters] = binSpikesPerEventMex(spkTimes,...
        bT.ephysWaitStr(idxCellTrial),...
        'Previous', p.prev,...
        'Post', p.post,...
        'BinSize', p.binSize,...
        'Hz', false);
    [eigenVecs(idxCellEig, :), scores(idxCellTrial, :),...
        eigenVals(idxCellEig, :), ~, explained(idxCellEig, :)] =...
        pca(cell2mat(binnedSpikes.').');
    cID(idxCellTrial) = [char(sessionNames(i)), '-cluster',...
        num2str(cellIDs(i))];
    cIDeig(idxCellEig) = [char(sessionNames(i)), '-cluster',...
        num2str(cellIDs(i))];
               
end

end
