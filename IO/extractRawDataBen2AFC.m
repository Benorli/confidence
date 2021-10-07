function [T] = extractRawDataBen2AFC(SessionData, T)
% EXCTRACTRAWDATA extract times from the rawdata in a SessionData struct 
% output from Bpod and add to the trial table

validateattributes(SessionData, {'struct'}, {})
validateattributes(T, {'table'}, {})

% T.trialEndTime = NaN(SessionData.nTrials, 1);
nTrials = SessionData.Custom.TrialNumber(end);
T.trialEndTime = NaN(nTrials,1);

% Get times for needed end states
sampleStartTime  = getTrialEventStart(SessionData, 'stimulus_delivery_min');
T.sampleStartTime = sampleStartTime(1:nTrials);
waitingStartTime = getTrialEventEnd(SessionData, 'wait_Sin');
T.waitingStartTime = waitingStartTime(1:nTrials);
T.lastState = categorical(getLastStates(SessionData, 1:SessionData.Custom.TrialNumber(end)));

unRewardedLeftIn      = getTrialEventTimes(SessionData, 'unrewarded_Lin');            
unRewardedRightIn     = getTrialEventTimes(SessionData, 'unrewarded_Rin');
unRewardedLeftGrace   = getTrialEventTimes(SessionData, 'unrewarded_Lin_grace');
unRewardedRightGrace  = getTrialEventTimes(SessionData, 'unrewarded_Rin_grace');

rewardedLeftIn      = getTrialEventTimes(SessionData, 'rewarded_Lin');            
rewardedRightIn     = getTrialEventTimes(SessionData, 'rewarded_Rin');
rewardedLeftGrace   = getTrialEventTimes(SessionData, 'rewarded_Lin_grace');
rewardedRightGrace  = getTrialEventTimes(SessionData, 'rewarded_Rin_grace');

water_L = getTrialEventStart(SessionData, 'water_L');
water_R = getTrialEventStart(SessionData, 'water_R');

for j = 1:height(T)   
    switch T.lastState(j)
        case 'timeOut_EarlyWithdrawal'
            T.trialEndTime(j) = nan;
        case 'timeOut_BrokeFixation'
            T.trialEndTime(j) = nan;          
        case 'timeOut_IncorrectChoice'             
            leftIn      = unRewardedLeftIn{j};
            rightIn     = unRewardedRightIn{j};
            leftGrace   = unRewardedLeftGrace{j};
            rightGrace  = unRewardedRightGrace{j};     
            
            if any(isnan(leftIn)) % animal went right
                if any(~isnan(rightGrace)) % there was a grace period
                    % Trial end is start of last grace
                    trialEndTime = rightGrace(end,1);
                else % There was no grace
                    % Trial end is end of rightIn
                    trialEndTime = rightIn(end,end);
                end
            else % animal went left
                if any(~isnan(leftGrace)) % there was a grace period
                    % Trial end is start of last grace
                     trialEndTime = leftGrace(end,1);
                else % There was no grace
                    % Trial end is end of leftIn
                    trialEndTime = leftIn(end,end);
                end
            end         
            T.trialEndTime(j) = trialEndTime;
        case 'timeOut_SkippedFeedback'    
            % Can be rewarded or unrewarded trial...
            if T.correctSideChosenBpod(j)
                leftIn      = rewardedLeftIn{j};
                leftGrace   = rewardedLeftGrace{j};
                rightIn     = rewardedRightIn{j};
                rightGrace  = rewardedRightGrace{j};
            else
                leftIn      = unRewardedLeftIn{j};
                leftGrace   = unRewardedLeftGrace{j};
                rightIn     = unRewardedRightIn{j};
                rightGrace  = unRewardedRightGrace{j};
            end
            
            if any(isfinite(rightIn)) % animal went right
                if any(~isnan(rightGrace)) % there was a grace period
                    % Trial end is start of last grace
                    trialEndTime = rightGrace(end,1);
                else % There was no grace
                    % Trial end is end of rightIn
                    trialEndTime = rightIn(end,end);
                end
            else % animal went left
                if any(~isnan(leftGrace)) % there was a grace period
                    % Trial end is start of last grace
                     trialEndTime = leftGrace(end,1);
                else % There was no grace
                    % Trial end is end of leftIn
                    trialEndTime = leftIn(end,end);
                end
            end     
            T.trialEndTime(j) = trialEndTime;            
        case 'water_L'       
            T.trialEndTime(j) = water_L(j);
        case 'water_R'
            T.trialEndTime(j) = water_R(j);
    end
end


%% Fix waiting time nan errors
% Reward drop out trials (rewarded and unrewarded) have NaN's as their
% waiting time value (because feedback was never given?) will calculate it
% here.

missingWT = isnan(T.waitingTime) & ...
    (T.lastState == 'timeOut_SkippedFeedback' | T.lastState == 'timeOut_IncorrectChoice');
waitingTimes = T.trialEndTime(missingWT) - T.waitingStartTime(missingWT);
T.waitingTime(missingWT) = waitingTimes;


%% Catch bug 
% Some trials (approx 4 in 1000) seem to suffer from a bug in the Bpod software 
% Reward is given almost immediatly even though the waiting time should be longer

% shortTrials = find((T.waitingTime < T.rewardDelayBpod) & (T.rewarded == true));




end % End function