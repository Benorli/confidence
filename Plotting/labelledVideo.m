function labelledVideo(varargin)

%% plot position Data on top of video of behaviour
% Plots frames of video from a trial along with text descriptions of
% behaviour and spike rasters/voltage traces. If multiple trials or
% selected will play them all in order and create a cumulative PSTH 
% Required Inputs: 
% clusterData : struct containing cluster data
% trial       : trial number to make
% Optional Parameter Pairs
% OutputFile  : path to save the video file, if not provided will not
%               export video
% Camera      : integer (1,2 or 3) whether to create video from data for
%               camera 1 or 2 or both (if boeth will also try to use 3d data
%              (default is 3)
% BodyParts     = a char, string or cell array containing body parts to plot, 
%               if not provided will default to implant
% Distance    : Plot the distance from the port below videos;
%                Logical, default = false.
% Acceleromoter: Plot the Acceleromoter data below videos;
%                Logical, default = false.
% Cluster     : Plot the spikes from the provided Cluster; Integer, default
%               is empty
% StartTime   : Time to start the video from, before the waiting end 
%               Default is empty which means waiting start; (+seconds)
% EndTime     : Time to End the video from, relative to waiting End.
%               Default is 0.5; (seconds)


%% Input parsing
p = inputParser; % Create object of class 'inputParser'
% define defaults
defOutputFile = []; % output file
defBodyParts  = {'implant'};
defCamera      = 3;
defLabel      = true;
defAccelerometer = false;
defDistance      = false;
defCluster       = [];
defStartTime     = [];
defEndTime       = 0.5;

% validation funs
valStruct = @(x) validateattributes(x, {'struct'},...
    {'nonempty'});
valTrialNum = @(x) validateattributes(x, {'numeric'},...
    {'scalar','nonempty','integer'});
valOutputFile = @(x) validateattributes(x, {'cell','char','string'},...
    {'nonempty'});
valBodyParts  = @(x) validateattributes(x, {'cell'},...
    {'nonempty'});
valCamera     = @(x) validateattributes(x, {'numeric'},...
    {'scalar','nonempty','integer','<=',3});
valTime     = @(x) validateattributes(x, {'numeric'},...
    {'scalar','nonempty','>=',0});


addRequired(p, 'clusterData', valStruct);
addRequired(p, 'Trial', valTrialNum);
addParameter(p, 'OutputFile', defOutputFile, valOutputFile);
addParameter(p, 'BodyParts', defBodyParts, valBodyParts);
addParameter(p, 'Camera', defCamera, valCamera);
addParameter(p, 'Label', defLabel, @islogical);
addParameter(p, 'Accelerometer', defAccelerometer, @islogical);
addParameter(p, 'Distance', defDistance, @islogical);
addParameter(p, 'Cluster', defCluster, valTrialNum);
addParameter(p, 'StartTime', defStartTime, valTime);
addParameter(p, 'EndTime', defEndTime, valTime);

parse(p, varargin{:});

trialNum        = p.Results.Trial;
clusterData     = p.Results.clusterData; 
bodyParts       = p.Results.BodyParts;
outputFile      = p.Results.OutputFile;
camera          = p.Results.Camera;
label           = p.Results.Label;
distance        = p.Results.Distance;
accelerometer   = p.Results.Accelerometer;
cluster         = p.Results.Cluster;
startTime       = p.Results.StartTime;
endTime         = p.Results.EndTime;

% Check trials exist
assert(any([clusterData.PositionFiles.Trial] == trialNum),...
    'Trial doesn''t appear to have existing position data');
positionFiles = find([clusterData.PositionFiles.Trial] == trialNum);

cam1File = positionFiles(...
             [clusterData.PositionFiles(positionFiles).Cam] == 1 & ...
             [clusterData.PositionFiles(positionFiles).Filtered]);
cam2File = positionFiles(...
             [clusterData.PositionFiles(positionFiles).Cam] == 2 & ...
             [clusterData.PositionFiles(positionFiles).Filtered]);            
cam3File = positionFiles(...
             [clusterData.PositionFiles(positionFiles).Cam] == 3);

positions.cam1 = loadDLCcsv([clusterData.PositionFiles(cam1File).folder ...
    filesep clusterData.PositionFiles(cam1File).name]);
positions.cam2 = loadDLCcsv([clusterData.PositionFiles(cam2File).folder ...
    filesep clusterData.PositionFiles(cam2File).name]);
if ~isempty(clusterData.PositionFiles(cam3File))
    positions.cam3 = loadDLCcsv([clusterData.PositionFiles(cam3File).folder ...
        filesep clusterData.PositionFiles(cam3File).name]);
end

% Will use ephys samples to synchronise everything, need sample rate
sRate   = clusterData.Header.frequency_parameters.amplifier_sample_rate; 

if accelerometer
    assert(isfield(clusterData,'Accelerometer'),'Must have accelerometer data loaded!');
end

% check cluster exists
if ~isempty(cluster)
    [clusterPresent,clusterID] = ismember(cluster,[clusterData.Clusters.ID]);
    assert(clusterPresent,...
        'Cluster ID provided isn''t found in cluster data...')
    cluster = clusterID;
end

hasPlot = accelerometer || distance || ~isempty(cluster);

%% Find Video files

videos.cam1 = clusterData.VideoFiles.Trials( ...
    [clusterData.VideoFiles.Trials.Cam] == 1 & ...
    [clusterData.VideoFiles.Trials.Trial] == trialNum);
videos.cam2 = clusterData.VideoFiles.Trials( ...
    [clusterData.VideoFiles.Trials.Cam] == 2 & ...
    [clusterData.VideoFiles.Trials.Trial] == trialNum);

%% Output video?
if isempty(outputFile)
    exportVideo = false;
else
    exportVideo = true;
end

% time basis for frames of video
frameInterval = round(median(diff(clusterData.VideoSync.time)),5); 
fps           = 1 ./ frameInterval;

% determine which bodyparts to plot
partNames = positions.cam1.Properties.VariableNames;
for j = 1:length(partNames)    
    parts = strsplit(partNames{j},'_');
    uniqueParts{j} = parts{1};
end
uniqueParts = unique(uniqueParts);

if ~isempty(bodyParts)         
    keep = zeros(size(uniqueParts));
    for j = 1:length(bodyParts)
        keep(contains(uniqueParts,bodyParts{j})) = 1;
    end
    uniqueParts(~keep) = [];
    assert(~isempty(uniqueParts),'No matching body parts found...');
end

clear p
    
%% Find the time points that define this trial
trialRow  = clusterData.SessionData(trialNum,:);
trialData.Start = trialRow.ephysTrialStartTime;
try
    % get 0.5 extra seconds after trial end (leaving decision/reward)
    trialData.End = trialRow.trialEndTime + trialRow.ephysTrialStartTime + 0.5; 
catch
    trialData.End = length(clusterData.Accelerometer)./clusterData.Header.frequency_parameters.amplifier_sample_rate;
end

% Get event times
trialData.SampleStart  = trialRow.sampleStartTime;
trialData.SampleEnd    = trialData.SampleStart + trialRow.samplingDuration;
trialData.WaitingStart = trialRow.waitingStartTime;
trialData.WaitingEnd   = trialRow.trialEndTime;

% Generate times to use for this actual video
if isempty(startTime)
    trialData.FigStart    = trialData.Start + trialData.WaitingStart;
else
    trialData.FigStart    = trialData.Start + trialData.WaitingEnd - startTime;
end

% Change the FigStart to match the video time if it is shorter
vidStartTime = clusterData.VideoSync.time(videos.cam1.FrameStart);
if vidStartTime > trialData.FigStart
    trialData.FigStart = vidStartTime;
end

trialData.FigEnd      = trialData.Start + trialData.WaitingEnd + endTime;

%% Assign Trial Outcomes   
trialData.Direction     = categorical(trialRow.highEvidenceSideBpod);
trialData.Outcome       = categorical(trialRow.trialOutcome);
trialData.Choice        = categorical(trialRow.sideChosen);
trialData.Rewarded      = trialRow.rewarded;   
trialData.Type          = trialRow.catchTrial;
% trialData.LeftClicks    = trialRow.leftSampledClicks{1};
% trialData.RightClicks   = trialRow.rightSampledClicks{1};
trialData.Evidence      = trialRow.decisionVariable;

%% Get Video Frame Info
frameIdx   = (videos.cam1.FrameStart:videos.cam1.FrameStart+(height(positions.cam1)-1))';
trialData.FrameStart = dsearchn(clusterData.VideoSync.time,trialData.FigStart);
trialData.FrameEnd   = dsearchn(clusterData.VideoSync.time,trialData.FigEnd);

trialData.FrameStartRel = dsearchn(frameIdx,trialData.FrameStart);
trialData.FrameEndRel   = dsearchn(frameIdx,trialData.FrameEnd);

trialData.Frames     = (trialData.FrameEndRel - trialData.FrameStartRel) + 1;
%% Get Distance Info
if distance
    % Get position data and convert to distance data
    % For now only implementing camera 1
    for partI = 1:length(uniqueParts)
        xPos = positions.cam1.([uniqueParts{partI} '_x']);
        yPos = positions.cam1.([uniqueParts{partI} '_y']);
        plotDistance(:,partI) = calculateDistanceFromPort(xPos,yPos,1);  
        plotTime = clusterData.VideoSync.time(trialData.FrameStart:trialData.FrameEnd) ...
            - (trialData.Start+trialData.WaitingEnd);
    end  
    
    plotDistance = plotDistance(trialData.FrameStartRel:trialData.FrameEndRel,:);
    while length(plotTime) > length(plotDistance)
        plotTime(end) = [];
    end
    % Find leaving decision using distance data;
    posLeavingTime = findLeavingPoint(plotDistance, plotTime, 0);    
end

%% Calculate frame time, plot time and a common basis
% Timebasis     = the temporal resolution used for the overall figure
% Timepoints    = the iteration used to update the figure
% Frames        = video frame count - synced to the Intan recording
% Latency       = Intan recording position (in samples)
% Time          = Intan recording position (in seconds)

if accelerometer || ~isempty(cluster)
    % Use a faster timebase to show spikes etc. Trying 2.5 ms
    trialData.TimeBasis = 0.0025; % in seconds;
else
    trialData.TimeBasis   = frameInterval;
end 
% Create a synchronsiation table for rendering
syncTable = createSyncTable(trialData.FigStart, trialData.FigEnd,...
                            trialData.WaitingEnd+trialData.Start,...
                            trialData.FrameStart,trialData.FrameEnd,...
                            trialData.FrameStartRel,...
                            clusterData,sRate,trialData.TimeBasis);
                    
           

%% Get Cluster Info

if ~isempty(cluster)
   % Get spike times, shifted to relative to waiting onset
   spikeTimes = clusterData.Clusters(cluster).Times - (trialData.Start + trialData.WaitingEnd);
   % Remove spikes outside our video frames
   spikeTimes(spikeTimes < -(startTime) | spikeTimes > syncTable.RelativeTime(end)) = [];
   
end
%% Setup Figure

% Adjust figure proportions to match video size
% vidHeight = vid{1}.Height;
% vidWidth  = vid{1}.Width;
% vidRatio  = vidWidth ./ vidHeight;

% tempVid = VideoReader([videos.cam1.folder filesep videos.cam1.name]);
% vidWidth = tempVid.Width;
% vidHeight = tempVid.Height;
% vidRatio = vidWidth./vidHeight;
% clear tempVid

fig = figure('Color',[1 1 1]);
if camera == 3 
    handles = calculateFigSize(3,hasPlot,'Figure',fig);
else
    handles = calculateFigSize(1,hasPlot,'Figure',fig);
end

fig = handles.fig;
fig.Units = 'normalized';
vidAx = handles.vidAx;
for j = 1:length(vidAx)
    vidAx.Units = 'normalized';
end
if hasPlot
    plotAx = handles.plotAx;
    plotAx.Units = 'normalized';
end

% Label with current info

if label
    % Calculate times 
    
    
    labelText = join(['Trial #' num2str(trialNum) ...
                 ',  Time = ' num2str(round(syncTable.RelativeTime(1),2)) ...
                 ', Frame #' num2str(syncTable.Frame(1))],'');

    labelBox = annotation(fig, 'textbox', [0.7 0.95 0.21 0.05],...
                          'String',labelText);
    
end

% Set a size callback to maintain the aspect ratio
% fig.SizeChangedFcn = @(src, evt)keepAspectRatio(src, evt);


%% setup axis objects

switch camera
    case 3
        posVideo(1) = positionVideo([videos.cam1.folder filesep videos.cam1.name],...
                                     positions.cam1,vidAx(1),syncTable,...
                                     'IncludedParts',uniqueParts);
        posVideo(1).initialiseFigure;
        
        posVideo(2) = positionVideo([videos.cam2.folder filesep videos.cam2.name],...
                                     positions.cam2,vidAx(2),syncTable,...
                                     'IncludedParts',uniqueParts);
        posVideo(2).initialiseFigure;         
        
        posAx       = positionAxis3D(positions.cam3,posAx,syncTable);    
        posAx.initialiseFigure;       
    case 2
        posVideo = positionVideo([videos.cam2.folder filesep videos.cam2.name],...
                                     positions.cam2,vidAx,syncTable,...
                                     'IncludedParts',uniqueParts);
        posVideo.initialiseFigure;         
    case 1
        posVideo = positionVideo([videos.cam1.folder filesep videos.cam1.name],...
                                     positions.cam1,vidAx,syncTable,...
                                     'IncludedParts',uniqueParts);
        posVideo.initialiseFigure       
end

if distance
    if ~isempty(cluster)
         plotObj = videoPlot(plotAx, syncTable,...
            'PlotData',plotDistance, 'TimeData', plotTime, ...
            'LeavingTime',0,'CalculatedLeaving',posLeavingTime,...
            'SpikeData',spikeTimes); 
    else
        plotObj = videoPlot(plotAx, syncTable,...
            'PlotData',plotDistance, 'TimeData', plotTime, ...
            'LeavingTime',0,'CalculatedLeaving',posLeavingTime); 
    end
    plotObj.initialisePlot();
end

% Setup image capture if needed
if exportVideo
    iter = 1;
    tempDir = ['temp' num2str(iter)];
    while exist(tempDir,'dir')
        iter = iter+1;
        tempDir = ['temp' num2str(iter)];
    end
    
    mkdir(tempDir);    
    tempName = [tempDir filesep 'temp'];

    % M(1) = getframe(fig);
    % export_fig([tempName num2str(timeI) '.jpg']);
    export_fig([tempName '1.png']);

end

%% Frame loop

for timeI = 2:height(syncTable)
  
    % update video & plots
    switch camera
        case 3
            posVideo(1).nextTimePoint;
            posVideo(2).nextTimePoint;
            posAx.nextTimePoint;
        otherwise
            posVideo.nextTimePoint;
    end 
    
    if hasPlot
        plotObj.nextTimePoint();
    end
    
  
    % update labels
    if label
    labelText = join(['Trial #' num2str(trialNum) ...
                 ',  Time = ' num2str(round(syncTable.RelativeTime(timeI),2)) ...
                 ', Frame #' num2str(syncTable.Frame(timeI))],'');

    labelBox.String = labelText;
    
    end
    if exportVideo
        % M(timeI) = getframe(fig);
        export_fig([tempName num2str(timeI) '.png']);
    end  
   
  
end % end trial Loop

fprintf('\n');

if exportVideo
    
%     vidObj = VideoWriter(outputFile,'MPEG-4');
%    % vidObj.FrameRate = (1/trialData.TimeBasis)./2;
%     open(vidObj)
%     disp('Writing Video');
%     for frameI = 2:length(M)
%         writeVideo(vidObj,M(frameI));
%     end
%     close(vidObj);
%     disp('Done!');
    
    %% FFmpeg command to make video from saved files
     % stitch together ffmpeg command 
     
    slowFactor = 10; % render film at 1/this number rate
     
     cmd = ['ffmpeg -y -r ' num2str(fps./slowFactor) ' -i ' tempDir filesep 'temp%d.png -c:v hevc_nvenc -preset fast ' ...
             '-b:v 2M -maxrate:v 3M -bufsize:v 3M "' outputFile '"'];
         
    [status, message] = system(cmd,'-echo');
    assert(contains(message,'muxing overhead'),'Video encode failed');

    
    % delete the temp folder
    rmdir(tempDir, 's')


end

end % End videoTrialData function

function handles = calculateFigSize(varargin)

%% Input parsing
p = inputParser; % Create object of class 'inputParser'
% define defaults
defExternalBorders = 0.05; % Borders between edge of figure and contents (%)
defInternalBorders = 0.025; % Borders between contents (%)
defVidWidth = 720;
defVidHeight = 540;
defFigure = [];

% validation funs
valNum = @(x) validateattributes(x, {'numeric'},...
    {'scalar','nonempty','integer'});
valBorder = @(x) validateattributes(x, {'numeric'},...
    {'scalar','nonempty'});

addRequired(p, 'nVideos', valNum);
addRequired(p, 'hasPlot', @islogical);
addParameter(p, 'ExternalBorders', defExternalBorders, valBorder);
addParameter(p, 'InternalBorders', defInternalBorders, valBorder);
addParameter(p, 'vidWidth', defVidWidth, valNum);
addParameter(p, 'vidHeight', defVidHeight, valNum);
addParameter(p, 'Figure', defFigure, @ishandle);

parse(p, varargin{:});

nVideos         = p.Results.nVideos;
hasPlot         = p.Results.hasPlot;
ExternalBorders = p.Results.ExternalBorders;
InternalBorders = p.Results.InternalBorders;
vidWidth        = p.Results.vidWidth;
vidHeight       = p.Results.vidHeight;
fig             = p.Results.Figure;

%% Calculate figure dimensions 
xBorder = round(ExternalBorders*vidWidth);
iBorder = round(InternalBorders*vidWidth);
plotHeight = round(vidHeight*0.25);


figWidth  = (vidWidth * nVideos) + 2*xBorder + round((nVideos-1)*iBorder);
figHeight = vidHeight + round(2*xBorder) + round(hasPlot*iBorder) + round(hasPlot*plotHeight);
figRatio = figHeight./figWidth;
normVidWidth = ( 1 - (2*ExternalBorders + 2*InternalBorders) ) ./ nVideos;


if ~isempty(fig)
    fig.Units = 'pixels';
    fig.Position(1) = 100;
    fig.Position(2) = 50;
    fig.Position(3) = figWidth;
    fig.Position(4) = figHeight;

    %     fig.Position(3) = 0.66;
%     fig.Position(4) = 0.66*figRatio;
    
    fig.Color = [1 1 1];
end


%% Calculate axis dimensions - in proportion of figure
if nVideos == 1 
    if hasPlot
        vidAx = axes('Units','normalized',...
            'Position',[ExternalBorders ExternalBorders+InternalBorders+0.2 ...
            (1-2*ExternalBorders) (1-(ExternalBorders+InternalBorders+0.25))],...
            'XTick',[],'YTick',[],'Box','off');
        plotAx = axes('Units','normalized',...
            'Position',[ExternalBorders ExternalBorders (1-2*ExternalBorders) 0.2]);
    else
        vidAx = axes('Position',[ExternalBorders ExternalBorders ...
            (1-2*ExternalBorders) (1-2*ExternalBorders)],...
        'XTick',[],'YTick',[],'Box','off');
    end
elseif nVideos == 3
     if hasPlot
        yPos = ExternalBorders+InternalBorders+plotHeight+0.2;
        plotAx = axes('Units','normalized',...
            'Position',[ExternalBorders ExternalBorders (1-2*ExternalBorders) 0.2]);
     else
         yPos = xBorder;
     end
     for vidI = 1:nVideos
         xPos = ExternalBorders + (normVidWidth+InternalBorders)*(vidI - 1);
         vidAx(vidI) = axes('Units','normalized',...
         'Position',[xPos yPos vidWidth vidHeight],...
            'XTick',[],'YTick',[],'Box','off');
     end
end


handles.vidAx = vidAx;
handles.plotAx = plotAx;
handles.fig = fig;
end % end calculateFigSize function

function syncTable = createSyncTable(startTime, endTime, waitingTime, ...
    startFrame, endFrame, startFrameRel, ...
    clusterData, sRate, timeBasis)
    
sampleInterval = 1./sRate;    
timeBaseSteps  = timeBasis ./ sampleInterval;
% Get ephys data latency - everything else syncs to this
Latency = (round(startTime*sRate):timeBaseSteps:round(endTime*sRate))';
points = length(Latency);
frameLatency = clusterData.VideoSync.latency(startFrame:endFrame);

frame = 1;
frameAdjust = startFrameRel - 1;
Frame = zeros(points,1);
for pointI = 1:points    
    % find the closest frame that is not more than 9 samples later than the
    % current latency
    if pointI == 1
        candidates = 1;
    else
        candidates = find(frameLatency - Latency(pointI) < 0);
    end
    Frame(pointI) = candidates(end) + frameAdjust;
end

RelativeTime = round((startTime:timeBasis:endTime) - waitingTime,6)';

syncTable = table(Latency,Frame,RelativeTime);

end % end createSyncTable function   