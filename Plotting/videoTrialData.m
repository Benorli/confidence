function videoTrialData(varargin)

%% plot spike rasters/voltage traces on top of video of behaviour
% Plots frames of video from a trial along with text descriptions of
% behaviour and spike rasters/voltage traces. If multiple trials or
% selected will play them all in order and create a cumulative PSTH 
% Required Inputs: 
% spikeTimes = a column vector of spike times,
% T          = a Table of Bpod data, must include the variable ephysTrialStartTime
% trialNum   = a vector of one or more trials to include in the render
% videoPath  = path to a video file
% videoSync  = table of video synchronisation data

% Optional Parameter Pairs
% 'VoltageTrace' = A struct exported from Spike 2 with voltage data

%% Input parsing
p = inputParser; % Create object of class 'inputParser'
% define defaults
defVoltageTrace = [];  % in ms
defOutputFile = []; % output file

% validation funs
valNumColNonEmpty = @(x) validateattributes(x, {'numeric'},...
    {'nonempty', 'column'});
valTable = @(x) validateattributes(x, {'table'},...
    {'nonempty'}); % Could build a custom validator for Bpod Table
valTrialNums = @(x) validateattributes(x, {'numeric'},...
    {'vector','nonempty','integer'});
% valVoltageTrace = @(x) validateattributes(x, {'struct'});
valOutputFile = @(x) validateattributes(x, {'string'});

addRequired(p, 'spikeTimes', valNumColNonEmpty);
addRequired(p, 'T', valTable);
addRequired(p, 'trialNum', valTrialNums);
addRequired(p, 'videoPath', @valVideoPath);
addRequired(p, 'videoSync', valTable);
addParameter(p, 'VoltageTrace', defVoltageTrace, @isstruct);
addParameter(p, 'OutputFile', defOutputFile);

parse(p, varargin{:});

spikeTimes   = p.Results.spikeTimes; 
T            = p.Results.T;
trialNum     = p.Results.trialNum;
% Check trials exist
if any(trialNum) > height(T)
    error('Trial Number provided doesn''t exist');
end
if length(trialNum) > 1
    plotPSTH = true;
else
    plotPSTH = false;
end

videoPath    = p.Results.videoPath;
videoSync    = p.Results.videoSync;
voltageTrace = p.Results.VoltageTrace;
outputFile   = p.Results.OutputFile;

% Output video?
if isempty(outputFile)
    exportVideo = false;
else
    exportVideo = true;
end

% time basis for frames of video
timeBasis = 100; % 100 = 10 ms

if ~isempty(voltageTrace)
    plotVoltage = true;
    % resample the voltage trace
    % downSampleFactor = (1./timeBasis)./voltageTrace.interval;
    % voltageTrace.values = voltageTrace.values(1:downSampleFactor:end);
    % voltageTrace.interval = 1./timeBasis;   
    % voltageTrace.length = length(voltageTrace.values);
    voltageTrace.time = (voltageTrace.start:voltageTrace.interval:...
        (voltageTrace.length-1).*voltageTrace.interval + voltageTrace.start)';   
else
    plotVoltage = false;
end

clear p

assert(any(strcmp(T.Properties.VariableNames,'ephysTrialStartTime')),...
    'Bpod Session Table doesn''t contain ephys trial start times...');
%% Initial Setup loop for multiple trials
% Quicker to gather all the video frames and trial data first
trialData(length(trialNum)) = struct('Start',[],'End',[],'SampleStart',[],...
    'SampleEnd',[],'WaitingStart',[],'WaitingEnd',[],...
    'TrialLength',[],'TimePoints',[],'SpikeTimes',[],...
    'PSTHValues',[],...
    'VoltageTrace',[],'VoltageTime',[],...
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
        trialData(trialI).End = spikeTimes(end);
    end

    % Get event times
    trialData(trialI).SampleStart  = trialRow.sampleStartTime;
    trialData(trialI).SampleEnd    = trialData(trialI).SampleStart + trialRow.samplingDuration;
    trialData(trialI).WaitingStart = trialRow.waitingStartTime;
    trialData(trialI).WaitingEnd   = trialRow.trialEndTime;

    % Create time base for rendering
    trialData(trialI).TrialLength = trialData(trialI).End - trialData(trialI).Start;  % trial length (s)
    trialData(trialI).TimePoints  = ceil(trialData(trialI).TrialLength *timeBasis); % create base time in 10 ms

    %% Get voltage trace
    if plotVoltage
       voltageStart = dsearchn(voltageTrace.time,trialData(trialI).Start);
       voltageEnd   = dsearchn(voltageTrace.time,trialData(trialI).End); 
       tempVolts = voltageTrace.values(voltageStart:voltageEnd);
       % Scale and center the voltageTrace
       tempVolts = tempVolts - min(tempVolts);
       tempVolts = tempVolts ./ max(tempVolts);
       trialData(trialI).VoltageTrace = tempVolts;
       trialData(trialI).VoltageTime  = linspace(0,trialData(trialI).TrialLength, ...
           length(tempVolts));
    end

    %% Find spikes
    currentSpikes = spikeTimes(spikeTimes >= trialData(trialI).Start & ...
                               spikeTimes <= trialData(trialI).End);
    currentSpikes = (currentSpikes - trialData(trialI).Start);
    trialData(trialI).SpikeTimes = currentSpikes;
    
    % Create Spike train audio
    Fs = 44000;
    t = linspace(0, trialData(trialI).TrialLength, Fs.*trialData(trialI).TrialLength);
    s = zeros(size(t));
    spikeIdx = dsearchn(t',currentSpikes);
    spikeWidth = 0.002 * Fs; % 2 ms long spikes
    for j = 1:length(spikeIdx)
        s(spikeIdx(j):spikeIdx(j)+spikeWidth) = 1;
    end
%     plot(t,s)
%     sound(s,Fs)
    trialData(trialI).SoundWave = s; clear s t spikeIdx
    
    %% Assign Trial Outcomes   
    trialData(trialI).Direction     = trialRow.highEvidenceSideBpod(:);
    trialData(trialI).Outcome       = trialRow.trialOutcome(:);
    trialData(trialI).Choice        = trialRow.sideChosen(:);
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
        end
    catch
        continue
    end
    clear vid
end


%% Setup Figure

fig      = figure('Color',[1 1 1]);
fig.Position(1) = fig.Position(1) - 0.5*fig.Position(3);
fig.Position(2) = fig.Position(2) - 0.5*fig.Position(4);
fig.Position(3) = fig.Position(3) .* 1.5;
fig.Position(4) = fig.Position(4) .* 1.5;

vidAx    = axes(fig,'Position',[0.05 0.175 0.9 0.75],...
    'XTick',[],'YTick',[],'Box','off');
if plotPSTH 
    % Calculate PSTH bins
    psthLims = [-max([trialData.WaitingEnd] - [trialData.WaitingStart]) 1];
    psthAx   = axes(fig,'Position',[0.05 0.04 0.9 0.07],'YTick',[],...
       'TickDir','out','XLim',psthLims);
    rasterAx = axes(fig,'Position',[0.05 0.16 0.9 0.09],'YTick',[],'TickDir','out');
       % XAxisLocation,'top');% 'XTick',[]);
else
    rasterAx = axes(fig,'Position',[0.05 0.05 0.9 0.1],'YTick',[],...
        'TickDir','out');
end

% fig.Visible = 'off';
% Set a size callback to maintain the aspect ratio
fig.SizeChangedFcn = @(src, evt)keepAspectRatio(src, evt);

% Setup some empty variables for psth
if plotPSTH
    psthSpikes = [];
    psthEvent  = [];
    psthLimit  = [];
end

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
    
    %% Construct Raster
    cla(rasterAx)
    rasterAx.XLim = [0 trialData(trialI).TrialLength];
    hold(rasterAx,'on')

    % Draw events    
    % Sampling
    sampleX = [trialData(trialI).SampleStart trialData(trialI).SampleStart ...
               trialData(trialI).SampleEnd   trialData(trialI).SampleEnd];
    sampleY = [0 1 1 0];
    samplePatch = patch(rasterAx, sampleX, sampleY, 'g',...
                  'FaceAlpha',0.3,'EdgeColor','none');

    % Waiting
    waitingX = [trialData(trialI).WaitingStart trialData(trialI).WaitingStart ...
        trialData(trialI).WaitingEnd trialData(trialI).WaitingEnd];
    waitingY = [0 1 1 0];
    waitingPatch = patch(rasterAx, waitingX, waitingY, 'r',...
                   'FaceAlpha',0.3,'EdgeColor','none');
               
    if plotVoltage           
        plot(rasterAx, trialData(trialI).VoltageTime, ...
            trialData(trialI).VoltageTrace,'k');
    else
        for spikeI = 1:length(trialData(trialI).SpikeTimes)
           line([trialData(trialI).SpikeTimes(spikeI) trialData(trialI).SpikeTimes(spikeI)],...
                [0 1], 'LineWidth',1,'Color','k');        
        end
    end
    
    % Patch to cover the raster - faster than redrawing each frame
    rasterCover = patch([-0.2 -0.2 trialData(trialI).TrialLength + 0.2 ...
        trialData(trialI).TrialLength + 0.2], [0 1 1 0],'w','EdgeColor','none');

    hold(rasterAx,'off')
    
    %% Calculate PSTH
    if plotPSTH
        %% Get cumulative spiketimes;
        psthSpikes = [psthSpikes; trialData(trialI).SpikeTimes + 100*trialI];
        psthEvent  = [psthEvent; trialData(trialI).WaitingEnd + 100*trialI];
        psthLimit  = [psthLimit; trialData(trialI).WaitingStart + 100*trialI];

        if isempty(psthSpikes)
            psthSpikes = nan;
        end
        
        [binnedSpikes, binCenters] = binSpikesPerEventMex(psthSpikes, ...
            psthEvent,'Previous', abs(psthLims(1)).*1000, ...
            'Post', psthLims(2).*1000, 'TrialLimits',psthLimit,...
            'BinSize', 100,  'Hz', false);
        binCenters = binCenters./1000;
        
        if trialI == 1
            binnedSpikes = cell2vec(binnedSpikes);
        else
            binnedSpikes = nanmean( reshape(cell2mat(binnedSpikes),...
                length(binCenters),trialI),2 );
        end
            
        % Set an initial empty bar plot
        if trialI == 1
            psthPlot = bar(psthAx, binCenters, zeros(size(binnedSpikes)), 'FaceColor','k',...
                'EdgeColor','none');
            psthAx.Box = 'off';
            hold(psthAx,'on');
            psthLine = line(psthAx,[psthLims(1) psthLims(1)],[0 1],'lineWidth',0.5,'lineStyle',':');
            hold(psthAx,'off');
        end
        psthAx.YLim  = [0 max([binnedSpikes; 1])];
        psthLine.YData = psthAx.YLim;
        psthXIdx = 1;
    end
    %% Frame loop
    for frameI = 1:trialData(trialI).TimePoints
        sTime = frameI ./ timeBasis;
        %% Video frame
        if ~isempty(trialData(trialI).Video)
            nFrames = length(trialData(trialI).VideoTime);
            if frameI == 1
                existingFrame = 0;
                nextFrameTime = trialData(trialI).VideoTime(currentFrame+1);  
            else
                existingFrame = currentFrame;
            end

            while nextFrameTime < sTime && currentFrame ~= nFrames-1
                currentFrame  = currentFrame + 1;
                nextFrameTime = trialData(trialI).VideoTime(currentFrame+1);
            end
            % Draw frame if needed
            if currentFrame ~= existingFrame
                cla(vidAx)
                vidImage = image(vidAx,trialData(trialI).Video{currentFrame});
                vidAx.XTick = [];
                vidAx.YTick = [];
                vidAx.Box = 'off';
                % axis(vidAx,'off');
            end
        end

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
            state = 'Pre-Trial Initiation';
            previousState = '';
        else
            previousStatus = state;
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
            try
                delete(statusBox)
            end
            % Construct Annotation
            statusBox = annotation(fig,'textbox',...
                'Position',[0.05 0.935, 0.9 0.05],...
                'String',state,'LineStyle','none',...
                'FontSize',12,'FontWeight','Bold',...
                'HorizontalAlignment','Right');
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
    
    soundData = [trialData.SoundWave];
    soundFile = [outputFile(1:end-4) '.wav'];
    audiowrite(soundFile,soundData,Fs); 
    
    vidObj = VideoWriter(outputFile,'MPEG-4');
    vidObj.FrameRate = timeBasis./2;
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

