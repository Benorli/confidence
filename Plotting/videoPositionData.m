function videoPositionData(varargin)

%% plot position Data on top of video of behaviour
% Plots frames of video from a trial along with text descriptions of
% behaviour and spike rasters/voltage traces. If multiple trials or
% selected will play them all in order and create a cumulative PSTH 
% Required Inputs: 
% positionTable = a table containing position data, generated from DLC data
% T             = a Table of Bpod data, must include the variable ephysTrialStartTime
% trialNum      = a vector of one or more trials to include in the render
% videoPath     = path to a video file
% videoSync     = table of video synchronisation data

% Optional Parameter Pairs
% samplingRate  = sampling rate of accelerometer data; default = 20000
% BodyParts     = a char, string or cell array containing body parts to plot, 
%               if not provided will plot all



%% Input parsing
p = inputParser; % Create object of class 'inputParser'
% define defaults
defOutputFile = []; % output file
defBodyParts    = [];

% validation funs
valTable = @(x) validateattributes(x, {'table'},...
    {'nonempty'}); % Could build a custom validator for Bpod Table
valTrialNums = @(x) validateattributes(x, {'numeric'},...
    {'vector','nonempty','integer'});
valOutputFile = @(x) validateattributes(x, {'string'});
valBodyParts    = @(x) validateattributes(x, {'cell','char','string'},...
    {'nonempty'});

addRequired(p, 'positionTable', valTable);
addRequired(p, 'T', valTable);
addRequired(p, 'trialNum', valTrialNums);
addRequired(p, 'videoPath', @valVideoPath);
addRequired(p, 'videoSync', valTable);
addParameter(p, 'OutputFile', defOutputFile);
addParameter(p, 'BodyParts', defBodyParts);

parse(p, varargin{:});

positionTable = p.Results.positionTable; 
T             = p.Results.T;
trialNum      = p.Results.trialNum;
bodyParts     = p.Results.BodyParts;
videoPath     = p.Results.videoPath;
videoSync     = p.Results.videoSync;
outputFile    = p.Results.OutputFile;

% Check trials exist
if any(trialNum) > height(T)
    error('Trial Number provided doesn''t exist');
end
if length(trialNum) > 1
    plotPSTH = true;
else
    plotPSTH = false;
end

% Output video?
if isempty(outputFile)
    exportVideo = false;
else
    exportVideo = true;
end

% time basis for frames of video
frameInterval = round(median(diff(videoSync.time)),5); 
fps           = 1 ./ frameInterval;
timeBasis     = fps; % Update image x times faster than frames

% determine which bodyparts to plot
partNames = positionTable.Properties.VariableNames;
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

assert(any(strcmp(T.Properties.VariableNames,'ephysTrialStartTime')),...
    'Bpod Session Table doesn''t contain ephys trial start times...');

clear p
%% Initial Setup loop for multiple trials
% Quicker to gather all the video frames and trial data first
trialData(length(trialNum)) = struct('Start',[],'End',[],'SampleStart',[],...
    'SampleEnd',[],'WaitingStart',[],'WaitingEnd',[],...
    'TrialLength',[],'TimePoints',[],'SpikeTimes',[],...
    'PSTHValues',[],...
    'AccTrace',[],'AccTime',[],...
    'Direction',[],'Type',[],'Choice',[],'Outcome',[],'Rewarded',[],...
    'Video',[],'VideoTime',[],'SoundWave',[],...
    'LeftClicks',[],'RightClicks',[],'Evidence',[]);

fprintf('Loading Trial Data and Video Frames...      ')
pC = 0;
for trialI = 1:length(trialNum)

    trialN = trialNum(trialI);   
    
    %% Find the time points that define this trial
    trialRow  = T(trialN,:);
    trialData(trialI).Start = trialRow.ephysTrialStartTime;
    try
        % get 0.5 extra seconds after trial end (leaving decision/reward)
        trialData(trialI).End = T(trialN+1,:).ephysTrialStartTime + 0.5; 
    catch
        trialData(trialI).End = length(accData)./samplingRate;
    end

    % Get event times
    trialData(trialI).SampleStart  = trialRow.sampleStartTime;
    trialData(trialI).SampleEnd    = trialData(trialI).SampleStart + trialRow.samplingDuration;
    trialData(trialI).WaitingStart = trialRow.waitingStartTime;
    trialData(trialI).WaitingEnd   = trialRow.trialEndTime;

    % Create time base for rendering
    trialData(trialI).TrialLength = trialData(trialI).End - trialData(trialI).Start;  % trial length (s)
    trialData(trialI).TimePoints  = ceil(trialData(trialI).TrialLength * timeBasis); % create base time in 0.1 ms points

    %% Assign Trial Outcomes   
    trialData(trialI).Direction     = categorical(trialRow.highEvidenceSideBpod);
    trialData(trialI).Outcome       = categorical(trialRow.trialOutcome);
    trialData(trialI).Choice        = categorical(trialRow.sideChosen);
    trialData(trialI).Rewarded      = trialRow.rewarded;   
    trialData(trialI).Type          = trialRow.catchTrial;
    % trialData(trialI).LeftClicks    = trialRow.leftSampledClicks{1};
    % trialData(trialI).RightClicks   = trialRow.rightSampledClicks{1};
    trialData(trialI).Evidence      = trialRow.decisionVariable;
    %% Find videoframes

    try
        % Check if trial times are outside video times
        if trialData(trialI).End > max(videoSync.time)
            continue
        else
            framesStart = dsearchn(videoSync.time, trialData(trialI).Start);
            framesEnd   = dsearchn(videoSync.time, trialData(trialI).End);
            nFrames     = (framesEnd - framesStart) + 1;

            vid = VideoReader(videoPath);
            vid.CurrentTime = (framesStart ./ vid.FrameRate);
            
            for frameI = 1:nFrames           
                trialData(trialI).VideoTime(frameI) = ...
                    videoSync.time(framesStart + (frameI - 1)) - trialData(trialI).Start;                
                trialData(trialI).Video{frameI} = vid.readFrame;
                
                % Progress counter
                fraction = 1./length(trialNum);
                percentComplete = round( (...
                    ((trialI-1)./length(trialNum)) + (frameI./nFrames).*fraction).*100, 1 );
                if pC ~= percentComplete
                    pC    = percentComplete;
                    pCStr = sprintf('%3.1f%%',pC);
                    fprintf(repmat('\b',1,length(pCStr)));
                    fprintf('%3.1f%%',pC);
                end
            end 
            
            % Extract positionData
            for bodyPartI = 1:length(uniqueParts)
                xName = [uniqueParts{bodyPartI} '_x'];
                yName = [uniqueParts{bodyPartI} '_y'];
                pName = [uniqueParts{bodyPartI} '_likelihood'];
                
                positionData(bodyPartI).x = positionTable.(xName)(framesStart:framesEnd);
                positionData(bodyPartI).y = positionTable.(yName)(framesStart:framesEnd);
                positionData(bodyPartI).p = positionTable.(pName)(framesStart:framesEnd);             
            end        
            partColours = colourPicker('Plasma',length(positionData));
        end
    catch
        continue
    end
    clear vid
end


%% Setup Figure

% Adjust figure proportions to match video size
vidHeight = size(trialData.Video{1},1);
vidWidth  = size(trialData.Video{1},2);
vidRatio  = vidWidth ./ vidHeight;

fig      = figure('Color',[1 1 1]);
fig.Position(1) = 0.05;
fig.Position(2) = 0.05;
fig.Position(4) = fig.Position(4) .* 1.1;
fig.Position(3) = fig.Position(4) .* vidRatio;

vidAx    = axes(fig,'Position',[0.05 0.2 0.9 0.7],...
    'XTick',[],'YTick',[],'Box','off');

traceAx = axes(fig,'Position',[0.05 0.05 0.9 0.2],'YTick',[],...
        'TickDir','out');

% fig.Visible = 'off';
% Set a size callback to maintain the aspect ratio
fig.SizeChangedFcn = @(src, evt)keepAspectRatio(src, evt);

filmFrame = 1;

%% Rendering Loop
for trialI = 1:length(trialNum)
    
    %% Static Annotations  
    if trialI > 1
        delete(trialLabelBox)
    end
    
    % Construct String
    trialLabel = '';
    if trialData(trialI).Type              
        trialLabel = [trialLabel 'Catch Trial, Evidence: '];
    else
        trialLabel = [trialLabel 'Standard Trial, Evidence: '];
    end
    trialLabel = [trialLabel char(trialData(trialI).Direction) ...
                 ', DV = ' num2str(round(trialData(trialI).Evidence,2))];

    trialLabelBox = annotation(fig,'textbox',...
        'Position',[0.05 0.935, 1 0.05],...
        'String',trialLabel,'LineStyle','none',...
        'FontSize',12,... %'FontWeight','Bold'
        'HorizontalAlignment','Left');

    currentFrame = 1;
    
    %% Construct Accelerometer Plot 
    
    yVal = 4.3; % 3 Normalised plots + 0.1 spacing gives 3.3
    
    cla(traceAx)
    traceAx.XLim = [0 trialData(trialI).TrialLength];
    traceAx.YLim = [0 yVal];
    hold(traceAx,'on')

    % Draw events    
    % Sampling
    sampleX = [trialData(trialI).SampleStart trialData(trialI).SampleStart ...
               trialData(trialI).SampleEnd   trialData(trialI).SampleEnd];
    sampleY = [0 yVal yVal 0];
    samplePatch = patch(traceAx, sampleX, sampleY, 'g',...
                  'FaceAlpha',0.3,'EdgeColor','none');

    % Waiting
    waitingX = [trialData(trialI).WaitingStart trialData(trialI).WaitingStart ...
        trialData(trialI).WaitingEnd trialData(trialI).WaitingEnd];
    waitingY = [0 yVal yVal 0];
    waitingPatch = patch(traceAx, waitingX, waitingY, 'r',...
                   'FaceAlpha',0.3,'EdgeColor','none');              

    colours = {'r','g','b'};
               
%     for traceI = 1:size(accData,1)
%         plot(traceAx, trialData(trialI).AccTime, ...
%             trialData(trialI).AccTrace(traceI,:),colours{traceI});
%     end
    
    % Patch to cover the raster - faster than redrawing each frame
    rasterCover = patch([-0.2 -0.2 trialData(trialI).TrialLength + 0.2 ...
        trialData(trialI).TrialLength + 0.2], [0 yVal yVal 0],'w','EdgeColor','none');

    hold(traceAx,'off')
    
    %% Frame loop
    previousStatus = '';
    nFrames = length(trialData(trialI).VideoTime);    
    
    for frameI = 1:trialData(trialI).TimePoints
        sTime = frameI ./ timeBasis;
        %% Video frame
        if ~isempty(trialData(trialI).Video)            
            if frameI == 1
                existingFrame = 0;
                nextFrameTime = trialData(trialI).VideoTime(currentFrame+1); 
                vidImage = image(vidAx,trialData(trialI).Video{currentFrame});
                vidAx.XTick = [];
                vidAx.YTick = [];
                vidAx.Box = 'off';                     
            else
                existingFrame = currentFrame;
            end

            while nextFrameTime < sTime && currentFrame ~= nFrames-1
                currentFrame  = currentFrame + 1;
                nextFrameTime = trialData(trialI).VideoTime(currentFrame+1);
            end
            % Draw frame if needed
            if currentFrame ~= existingFrame
                vidImage.CData = trialData(trialI).Video{currentFrame};
            end
        end

        %% Position Data
        hold(vidAx,'on');
        if currentFrame == 1 || frameI == 1
            for partI = 1:length(positionData)                
                positionData(partI).Handle = ...
                    scatter(vidAx,positionData(partI).x(currentFrame),...
                    positionData(partI).y(currentFrame),...
                    'markerEdgeColor','none','markerFaceColor',partColours(partI,:));                                    
                    if positionData(partI).p(currentFrame) <= 0.95
                        positionData(partI).Handle.Visible = 'off'; % only draw if high confidence
                    end
            end
        else
            for partI = 1:length(positionData) 
                positionData(partI).Handle.XData = positionData(partI).x(currentFrame);
                positionData(partI).Handle.YData = positionData(partI).y(currentFrame);     
                if positionData(partI).p(currentFrame) <= 0.95
                    positionData(partI).Handle.Visible = 'off'; % only draw if high confidence
                else
                    positionData(partI).Handle.Visible = 'on';
                end
            end
        end   
        hold(vidAx,'off');
        %% Modify patch covering raster - faster than re-drawing every frame
           rasterCover.Vertices(1:2,1) = sTime;

        %% Update PSTH
        if plotPSTH && psthXIdx <= length(binCenters)
            % Calculate current plot time in -ve seconds from end of
            % waiting time
            psthTime = sTime - trialData(trialI).WaitingEnd;
            psthXVal = psthPlot.XData(psthXIdx);
            if psthTime > psthXVal 
                psthPlot.YData(psthXIdx) = binnedSpikes(psthXIdx);
                psthLine.XData = [binCenters(psthXIdx)+0.05 ...
                    binCenters(psthXIdx)+0.05];
                psthXIdx = psthXIdx + 1;                
            end   
        end
        %% Dynamic annotations and titles
        if frameI == 1
            state = '\color{gray}Pre-Trial Initiation';
            previousState = '';
            % Construct Annotation
            statusBox = annotation(fig,'textbox',...
                'Position',[0.05 0.935, 0.9 0.05],...
                'String',state,'LineStyle','none',...
                'FontSize',12,'FontWeight','Bold',...
                'HorizontalAlignment','Right');           
        else
            previousState = state;
        end
        
        if sTime < trialData(trialI).SampleStart
            state = '\color{gray}Pre-Trial Initiation';
        elseif sTime >= trialData(trialI).SampleStart && ...
               sTime <= trialData(trialI).SampleEnd
            state = 'Sampling';
        elseif sTime > trialData(trialI).SampleEnd && ...
               sTime < trialData(trialI).WaitingStart
            state = 'Choosing';
        elseif sTime >= trialData(trialI).WaitingStart && ...
               sTime <= trialData(trialI).WaitingEnd
%                if strcmp(trialData(trialI).Choice, trialData(trialI).Direction)
                if trialData(trialI).Choice == trialData(trialI).Direction
                    state = '\color{green}Correct, Waiting';
                else
                    state = '\color{red}Incorrect, Waiting';
                end
%                 if ~trialData(trialI).Type
%                     state = [state ' for Reward'];
%                 end
         elseif sTime > trialData(trialI).WaitingEnd   
             if trialData(trialI).Rewarded
                 state = '\color{green}Reward';
             else
                 state = '\color{red}Leaving Decision';
             end              
        end % End status selection 
                    
        if ~strcmp(state,previousState)
            % disp('status changed');
            statusBox.String = state;
        end

        %% Draw  
        drawnow
        
        if exportVideo
            M(filmFrame) = getframe(fig);
            filmFrame = filmFrame + 1;
        end
    end
end % end trial Loop

fprintf('\n');

if exportVideo
    
%     soundData = [trialData.SoundWave];
%     soundFile = [outputFile(1:end-4) '.wav'];
%     audiowrite(soundFile,soundData,Fs); 
%     
    vidObj = VideoWriter(outputFile,'MPEG-4');
   % vidObj.FrameRate = timeBasis;

    open(vidObj)
    disp('Writing Video');
    for frameI = 1:filmFrame-1
        writeVideo(vidObj,M(frameI));
    end
    close(vidObj);
    disp('Done!');
    
    % videoFWriter = vision.VideoFileWriter('Test.mp4', 'FileFormat', 'MPEG4', 'FrameRate', 30, 'AudioInputPort', true);
    % videoFWriter.VideoCompressor = 'MJPEG Compressor';
end

end % End videoTrialData function



function isVideo = valVideoPath(videoPath)
isVideo = false;
if exist(videoPath,'file')
    vid = VideoReader(videoPath);
    if ~isempty(vid)
        isVideo = true;
    end
end

end % End isVideo Validation function

function keepAspectRatio(src, evt)

currentAspectRatio = src.Position(3) ./ src.Position(4);

if round(currentAspectRatio,3) ~= 1.333
    x = src.Position(3);
    y = src.Position(4);
    
    % Calculate the x/y values based on each other
    posX = round(1.333 * y);
    posY = round(0.75  * x);
    
    % Change the one that requires the smallest pixel difference
    [~, changeIdx] = min( [abs(posX - x) abs(posY - y)] );

    if changeIdx == 1 % Change the X value
        src.Position(3) = posX;
    else
        src.Position(4) = posY;
    end
end

end % End keepAspectRatio function