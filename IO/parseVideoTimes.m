function [videoSync, T] = parseVideoTimes(videoPath, camTTLPath, T)
%% Sync camera acquisition TTL pulses with ephys and bpod times
% Inputs: videoPath  = path to video file
%         camTTLPath = path to matlab format TTL events exported from spike2
%         T          = Bpod Session data Table

% Todo = Add per trial video frame start and stop points

%% Load Video
try
    vid = VideoReader(videoPath);
catch
    error('Video file wouldn''t load');
end

% Load camera TTL times
try
    camTTL = load(camTTLPath);
    % Need to select field dynamically as name varies
    fieldNames = fieldnames(camTTL);
    ttls = camTTL.(fieldNames{1}).times;
catch
    error('TTL times wouldn''t load');
end

    
%% Check if the frame rate & duration match the camera events       
nFrames = vid.Duration.*vid.FrameRate; % Estimate number of frames
% Check for discontinuities in camera events
frameDiffs = round(diff(ttls),4);
frameInterval = 1./vid.FrameRate;
discont = find(frameDiffs > frameInterval + 0.001);

if ~isempty(discont)
    for j = 1:length(discont)+1
        if j == 1
            eventCounts(j,1) = 1;
            eventCounts(j,2) = discont(j);
        elseif j == length(discont)+1
            eventCounts(j,1) = discont(j-1)+1;
            eventCounts(j,2) = length(cameraEvents);
        else
            eventCounts(j,1) = discont(j-1)+1;
            eventCounts(j,2) = discont(j);
        end
    end
else
    eventCounts(1,1) = 1;
    eventCounts(1,2) = length(ttls);
end

sectionIdx = dsearchn(diff(eventCounts')',nFrames);    
matchTimes = ttls( eventCounts(sectionIdx,1):eventCounts(sectionIdx,2) );

if nFrames == length(matchTimes)
    disp('Video frames match Camera TTL exactly...');
    videoData(1:nFrames) = struct('frame',[], 'time',[]);
    frames  = num2cell(1:nFrames);
    time    = num2cell(matchTimes);
    [videoData.frame] = frames{:};
    [videoData.time]  = time{:};   
elseif length(matchTimes) < nFrames
    % There are less camera events than the number of video frames
    % Need to determine where the video frames start...
    warning(['More video frames than camera TTL events...' ...
             ' Cannot disambinguate recording timing...']);
    videoSync = [];
    return
elseif nFrames < length(matchTimes)
    % video is shorter than event count 
    % check that video starts after recording
    if matchTimes(1) > 0 
        % Check whether there are more trials after the video stops        
        lastFrame = matchTimes(eventCounts(sectionIdx,1) + (nFrames - 1));
        if any(T.ephysTrialStartTime > lastFrame)
            warning(['There are more trials after the video stops...' ...
             ' Possible that video is mismatched, check carefully!']);
        end       
        videoData(1:nFrames) = struct('frame',[], 'time',[]);
        frames  = num2cell(1:nFrames);        
        time    = num2cell(matchTimes(1:nFrames));
        [videoData.frame] = frames{:};
        [videoData.time]  = time{:};     else
        warning(['Video TTL marks start before recording...' ...
             ' Cannot disambinguate recording timing...']);
        videoSync = [];
        return
    end            
end

%% Update the bpod session table to include video data for each trial
% Also add trial data to videoSync
time = [videoData.time]';
[videoStartFrame, videoEndFrame] = deal(nan(height(T),1));
for trialI = 1:height(T)
    trialStart = T.ephysTrialStartTime(trialI);
    trialEnd   = trialStart + T.trialEndTime(trialI);
    % Skip trials without ephys data or before the video starts
    if isnan(trialStart) || trialStart < min(time) || trialEnd > max(time)        
       continue
    else  
        % Find starting frame
        closestFrame = ...
            dsearchn(time, trialStart);
        frameTime = time(closestFrame);
        while frameTime < trialStart
        % Check the next frame
            closestFrame = closestFrame + 1;
            frameTime = time(closestFrame);
        end
        videoStartFrame(trialI) = closestFrame;
        
        % Find end frame
        closestFrame = ...
            dsearchn(time, trialEnd);
        frameTime = time(closestFrame);
        while frameTime < trialEnd
        % Check the next frame
            closestFrame = closestFrame + 1;
            frameTime = time(closestFrame);
        end
        videoEndFrame(trialI) = closestFrame-1;  
        
        % Assign trials to video data
        for frameI = videoStartFrame(trialI):videoEndFrame(trialI)
            videoData(frameI).trial = trialI;
        end
    end
end

videoSync = struct2table(videoData);
T.videoStartFrame = videoStartFrame;
T.videoEndFrame   = videoEndFrame;

%         trialMatch = dsearchn(T.ephysTrialStartTime,matchTimes(1:nFrames));
%         trialNum = zeros(size(trialMatch));
%         for j = 1:length(trialMatch) % Loop through and add trial number            
%             if T.ephysTrialStartTime(trialMatch(j)) >= videoData(j).time
%                 trialNum(j) = trialMatch(j) - 1;
%             else
%                 trialNum(j) = trialMatch(j);
%             end          
%         end
%         trial = num2cell(trialNum);

% % Save sync table
% try
%     disp('Writing sync table to disk...');
%     writetable(videoSyncTable,[videoPath(1:end-4) '_VideoSync.tsv'],...
%            'Delimiter','\t','FileType','text');
% catch    
%     disp('Failed to write sync table to disk');
%     return
% end

end % end parseVideoTimes function 