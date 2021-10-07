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
%               if not provided will plot all


%% Input parsing
p = inputParser; % Create object of class 'inputParser'
% define defaults
defOutputFile = []; % output file
defBodyParts  = [];
defCamera      = 3;
defLabel      = true;

% validation funs
valStruct = @(x) validateattributes(x, {'struct'},...
    {'nonempty'});
valTrialNum = @(x) validateattributes(x, {'numeric'},...
    {'scalar','nonempty','integer'});
valOutputFile = @(x) validateattributes(x, {'cell','char','string'},...
    {'nonempty'});
valBodyParts  = @(x) validateattributes(x, {'cell','char','string'},...
    {'nonempty'});
valCamera     = @(x) validateattributes(x, {'numeric'},...
    {'scalar','nonempty','integer','<=',3});

addRequired(p, 'clusterData', valStruct);
addRequired(p, 'Trial', valTrialNum);
addParameter(p, 'OutputFile', defOutputFile, valOutputFile);
addParameter(p, 'BodyParts', defBodyParts, valBodyParts);
addParameter(p, 'Camera', defCamera, valCamera);
addParameter(p, 'Label', defLabel, @islogical);

parse(p, varargin{:});

trialNum    = p.Results.Trial;
clusterData = p.Results.clusterData; 
bodyParts   = p.Results.BodyParts;
outputFile  = p.Results.OutputFile;
camera      = p.Results.Camera;
label       = p.Results.Label;

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
positions.cam3 = loadDLCcsv([clusterData.PositionFiles(cam3File).folder ...
    filesep clusterData.PositionFiles(cam3File).name]);

nFrames = height(positions.cam1);

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
timeBasis     = fps; % Update image x times faster than frames

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

videoSync = clusterData.VideoSync;

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

% Create time base for rendering
trialData.TrialLength = trialData.End - trialData.Start;  % trial length (s)
trialData.TimePoints  = ceil(trialData.TrialLength * timeBasis); % create base time in 0.1 ms points

%% Assign Trial Outcomes   
trialData.Direction     = categorical(trialRow.highEvidenceSideBpod);
trialData.Outcome       = categorical(trialRow.trialOutcome);
trialData.Choice        = categorical(trialRow.sideChosen);
trialData.Rewarded      = trialRow.rewarded;   
trialData.Type          = trialRow.catchTrial;
% trialData.LeftClicks    = trialRow.leftSampledClicks{1};
% trialData.RightClicks   = trialRow.rightSampledClicks{1};
trialData.Evidence      = trialRow.decisionVariable;

%% Setup Figure

% Adjust figure proportions to match video size
% vidHeight = vid{1}.Height;
% vidWidth  = vid{1}.Width;
% vidRatio  = vidWidth ./ vidHeight;

fig      = figure('Color',[1 1 1]);
fig.Position(1) = 100;
fig.Position(2) = 100;

if camera == 3
    fig.Position(4) = fig.Position(4) .* 1.1;
    fig.Position(3) = fig.Position(4) .* 3;
    vidAx(1) = axes(fig,'Position',[0.05 0.05 0.28333 0.9],...
    'XTick',[],'YTick',[],'Box','off');
    vidAx(2) = axes(fig,'Position',[0.35833 0.05 0.28333 0.9],...
    'XTick',[],'YTick',[],'Box','off');
    posAx = axes(fig,'Position',[0.666 0.05  0.28333 0.9]);
else
    fig.Position(4) = fig.Position(4) .* 1.1;
    fig.Position(3) = fig.Position(3) .* 1.1;
    vidAx = axes(fig,'Position',[0.05 0.5 0.9 0.9],...
    'XTick',[],'YTick',[],'Box','off');
end



% Label with current info

if label
    % Calculate times 
    frameTimes = videoSync.time(videos.cam1.FrameStart:videos.cam1.FrameEnd);
    frameTimes = seconds(round(frameTimes - (trialData.Start + trialData.WaitingEnd),2));
    
    % frameTimes.Format ='mm:ss.SSS';
  
    labelText = join(['Trial #' num2str(trialNum) ...
                 ',  Time = ' string(frameTimes(1)) ...
                 ', Frame #1'],'');

    labelBox = annotation(fig, 'textbox', [0.78 0.95 0.21 0.05],...
                          'String',labelText);
    
end

% Set a size callback to maintain the aspect ratio
% fig.SizeChangedFcn = @(src, evt)keepAspectRatio(src, evt);



%% setup axis objects

switch camera
    case 3
        posVideo(1) = positionVideo([videos.cam1.folder filesep videos.cam1.name],...
                                     positions.cam1,vidAx(1));
        posVideo(1).initialiseFigure;
        
        posVideo(2) = positionVideo([videos.cam2.folder filesep videos.cam2.name],...
                                     positions.cam2,vidAx(2));
        posVideo(2).initialiseFigure;         
        
        posAx       = positionAxis3D(positions.cam3,posAx);    
        posAx.initialiseFigure;       
    case 2
        posVideo = positionVideo([videos.cam2.folder filesep videos.cam2.name],...
                                     positions.cam2,vidAx);
        posVideo.initialiseFigure;         
    case 1
        posVideo = positionVideo([videos.cam1.folder filesep videos.cam2.name],...
                                     positions.cam1,vidAx);
        posVideo.initialiseFigure;           
end
currentFrame = 1;


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
end

%% Frame loop
if exportVideo
    export_fig([tempName '1.jpg']);
end  

for frameI = 2:nFrames
  
    % update video & plots
    switch camera
        case 3
            posVideo(1).updateFrame;
            posVideo(2).updateFrame;
            posAx.updateFrame;
        otherwise
            posVideo.updateFrame;
    end 
    % update labels
    if label
    labelText = join(['Trial #' num2str(trialNum) ...
                 ',  Time = ' string(frameTimes(frameI)) ...
                 ', Frame #' num2str(frameI)],'');

    labelBox.String = labelText;
    
    end
    if exportVideo
        export_fig([tempName num2str(frameI) '.jpg']);
    end  
   
  
end % end trial Loop

fprintf('\n');

if exportVideo
    
    %% FFmpeg command to make video from saved files
     % stitch together ffmpeg command 
     
    slowFactor = 2; % render film at 1/this number rate
     
     cmd = ['ffmpeg -r ' num2str(fps./slowFactor) ' -i ' tempDir filesep 'temp%d.jpg -c:v hevc_nvenc -preset fast ' ...
             '-b:v 2M -maxrate:v 3M -bufsize:v 3M ' outputFile];
         
    [status, message] = system(cmd,'-echo');
    assert(contains(message,'muxing overhead'),'Video encode failed');

    
    % delete the temp folder
    rmdir(tempDir, 's')


end

end % End videoTrialData function
