%{
----------------------------------------------------------------------------

This file is part of the Bpod Project
Copyright (C) 2014 Joshua I. Sanders, Cold Spring Harbor Laboratory, NY, USA

----------------------------------------------------------------------------

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, version 3.

This program is distributed  WITHOUT ANY WARRANTY and without even the
implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
%}

function Click2AFCRewPulsSingleSlim2
% This protocol demonstrates the Poisson Click task using Pulse Pal.
% Written by Josh Sanders, 10/2014.
% Modified by Paul Masset 3/2015.
% Modified by Michael Lagler 05/2018.

% Most recent change: improved processing time using figure handles
%
% SETUP
% You will need:
% - A Pulse Pal with software installed on this computer
% - A BNC cable between Bpod's BNC Output 1 and Pulse Pal's Trigger channel 1
% - Left and right speakers connected to Pulse Pal's output channels 1 and 2 respectively

global BpodSystem

%% Define parameters (loading into live paramter view)
S.ProtocolSettings = BpodSystem.ProtocolSettings; % Load settings chosen in launch manager into current workspace as a struct called S
S.GUI.StimulusDelayMin = S.ProtocolSettings.StimulusDelayMin;
S.GUI.StimulusDelayMax = S.ProtocolSettings.StimulusDelayMax;
S.GUI.StimulusDelayExp = S.ProtocolSettings.StimulusDelayExp;
S.GUI.TimeForResponse = 20; % Time after sampling for subject to respond (s)
S.GUI.RewardAmountLeft = 10; % Left amount given in microliters
S.GUI.RewardAmountRight = 10;% Right amount given in microliters
S.GUI.TimeoutDuration = S.ProtocolSettings.TimeoutDuration; % Duration of punishment timeout (s)
S.GUI.StimulusDuration = 0.35; % Duration of the sound
S.GUI.Alpha = S.ProtocolSettings.Alpha; % Alpha parameter of the prior beta distribution
S.GUI.SumRates = 100; % Sum of the firing rates
S.GUI.CatchTrialProbability = 0; % Probability of having a catch trial
S.GUI.MaxMinimumSamplingDuration = 0.3; % max Minimum sampling duration to have a valid trial
S.GUI.InitialMinimumSamplingDuration = 0.2; % Minimum sampling duration to have a valid trial at begining of session
S.GUI.ProportionCatchFifty50 = 0; % Proportion of catch trials with omega=0.5;
S.GUI.ProportionNormalFifty50 = 0; % Proportion of Normal trials with omega=0.5 (0 means sampled randomly);
S.GUI.EarlyTimeOut = S.ProtocolSettings.EarlyTimeOut; % Timeout for early Withdrawal
% S.GUI.MinimumRewardDelay = S.ProtocolSettings.MinimumRewardDelay; % Minimum value of reward delay
% S.GUI.MaximumRewardDelay = S.ProtocolSettings.MaximumRewardDelay; % Cutoff for reward delay distribution
% S.GUI.ExponentRewardDelay = S.ProtocolSettings.ExponentRewardDelay; % Time constant of reward delay distribution
S.GUI.MinimumRewardDelayLeft = S.ProtocolSettings.MinimumRewardDelay; % Minimum value of reward delay
S.GUI.MaximumRewardDelayLeft = S.ProtocolSettings.MaximumRewardDelay; % Cutoff for reward delay distribution
S.GUI.ExponentRewardDelayLeft = S.ProtocolSettings.ExponentRewardDelay; % Time constant of reward delay distribution
S.GUI.MinimumRewardDelayRight = S.ProtocolSettings.MinimumRewardDelay; % Minimum value of reward delay
S.GUI.MaximumRewardDelayRight = S.ProtocolSettings.MaximumRewardDelay; % Cutoff for reward delay distribution
S.GUI.ExponentRewardDelayRight = S.ProtocolSettings.ExponentRewardDelay; % Time constant of reward delay distribution
S.GUI.RewardGrace = 0.1; % Grace period for fast pulling in and out for reward port, rewarded trials
S.GUI.PunishGrace = 0.1; % Grace period for fast pulling in and out for reward port, non-rewarded trials
S.GUI.MaxPortInTime = 30; % Time rat can stay in punish port
S.GUI.AnalysisStart = 0; % StartTrial for analysis
S.GUI.AnalysisEnd = 0; % EndTrial for analysis
S.GUI.RewardBias = 0; % This is reward counter bias to counteract choice bias
S.GUI.RewardBWindow = 100;
S.GUI.RewardBFactor = 1;
S.GUI.PunSound = 1; % This controls the early withdrawal punishment sound (0 = OFF, 1 = ON)
S.GUI.GraceEndIndicator = 1; % This controls the GraceEndIndicator sound (0 = OFF, 1 = ON)
S.GUI.ConfidenceReport = 0; % This controls confidence report analysis (0 = only catch trials, 1 = with correct non-catch)
S.GUI.WTlimitLow = 1;
S.GUI.WTlimitHigh = 8;
S.GUI.WTDropOutPun = 0;

%% Initialize parameter GUI plugin
BpodParameterGUI('init',S);

%% Initialize and program PulsePal
PulsePal
load EarlyWithdrawalProgramUP2.mat
PulsePalEarlyWithdrawal = ParameterMatrix;
load Click2AFCPulsePalProgramUP2.mat
ProgramPulsePal(ParameterMatrix);
OriginalPulsePalMatrix = ParameterMatrix;

%% Predefine trials
MaxTrials = 5000;
TrialTypes = ceil(rand(1,MaxTrials)*2);
BpodSystem.Data.TrialTypes = []; % The trial type of each trial completed will be added here

%% PRE-ALLOCATION
WindowSize=S.ProtocolSettings.WindowSize;
OKTrial(1:(WindowSize+1))=NaN;

%% Create field for Data structure / PRE-ALLOCATION
BpodSystem.Data.MinimumSamplingDuration = S.GUI.InitialMinimumSamplingDuration;
BpodSystem.Data.SamplingDuration = [];
BpodSystem.Data.nTrials = [];
BpodSystem.Data.Threshold = [];
BpodSystem.Data.WindowSize = [];
BpodSystem.Data.SamplingValue = [];
BpodSystem.Data.TrialTypes = []; % Adds the trial type of the current trial to data
BpodSystem.Data.FastClickRate = []; % Adds the value of fast click rate
BpodSystem.Data.SlowClickRate = []; % Adds the vlaue of slow click rate
BpodSystem.Data.CatchTrial = []; % 1 if trial is a Catch trial, 0 otherwise
BpodSystem.Data.Omega = []; % Adds the value of omega;
BpodSystem.Data.RewardDelay = []; % Adds the reward delay
BpodSystem.Data.RewardGrace = [];
BpodSystem.Data.StimulusDelayMin = S.GUI.StimulusDelayMin; % Duration of initial delay (s)
BpodSystem.Data.StimulusDelayMax = S.GUI.StimulusDelayMax; % Duration of initial delay (s)
BpodSystem.Data.StimulusDelayExp = S.GUI.StimulusDelayExp; % Duration of initial delay (s)
BpodSystem.Data.TimeForReponse = []; % Time after sampling for subject to respond (s)
BpodSystem.Data.RewardAmountRight = [];
BpodSystem.Data.RewardAmountLeft = []; % amount of large reward delivered to the rat in microliters
BpodSystem.Data.TimeoutDuration = []; % Duration of punishment timeout (s)
BpodSystem.Data.StimulusDuration = []; % Duration of the sound
BpodSystem.Data.Alpha = []; % Alpha parameter of the prior beta distribution
BpodSystem.Data.SumRates = []; % Sum of the firing rates
BpodSystem.Data.CatchTrialProbability = []; % Probability of having a catch trial
BpodSystem.Data.MaxMinimumSamplingDuration = []; % max Minimum sampling duration to have a valid trial
BpodSystem.Data.ProportionCatchFifty50 = []; % Proportion of catch trials with omega=0.5;
BpodSystem.Data.ProportionNormalFifty50 = []; % Proportion of Normal trials with omega=0.5 (0 means sampled randomly);
BpodSystem.Data.EarlyTimeOut = []; % Timeout for early Withdrawal
% BpodSystem.Data.MinimumRewardDelay = []; % Minimum value of reward delay
% BpodSystem.Data.MaximumRewardDelay = []; % Cutoff for reward delay distribution
% BpodSystem.Data.ExponentRewardDelay = []; % Time constant of reward delay distribution
BpodSystem.Data.MinimumRewardDelayLeft = []; % Minimum value of reward delay
BpodSystem.Data.MaximumRewardDelayLeft = []; % Cutoff for reward delay distribution
BpodSystem.Data.ExponentRewardDelayLeft = []; % Time constant of reward delay distribution
BpodSystem.Data.MinimumRewardDelayRight = []; % Minimum value of reward delay
BpodSystem.Data.MaximumRewardDelayRight = []; % Cutoff for reward delay distribution
BpodSystem.Data.ExponentRewardDelayRight = []; % Time constant of reward delay distribution
BpodSystem.Data.RewardGrace = [];
BpodSystem.Data.PunishGrace = [];
BpodSystem.Data.PunishedTrial = [];
BpodSystem.Data.SampledTrial = []; % 1 if sampled enough 0, if withdrew early
BpodSystem.Data.CorrectSide = []; % Array of correct Sides
BpodSystem.Data.NFastClick = [];
BpodSystem.Data.NSlowClick = [];
BpodSystem.Data.NLeftClick = [];
BpodSystem.Data.NRightClick = [];
BpodSystem.Data.ChosenDirection = [];
BpodSystem.Data.HumanCounter = 1;
BpodSystem.Data.StartTrial = [];
BpodSystem.Data.EndTrial = [];
BpodSystem.Data.CurrentEarlyWithdrawal = 0;
BpodSystem.Data.CurrentEarlyWithdrawalLeft = 0;
BpodSystem.Data.CurrentEarlyWithdrawalRight = 0;
BpodSystem.Data.CurrentSamplingDuration = 0;
BpodSystem.Data.TotalRewardGiven = 0;
BpodSystem.Data.CurrentWindow = [];
BpodSystem.Data.ProcessingTime1 = 0;
BpodSystem.Data.ProcessingTime2 = 0;
BpodSystem.Data.ProcessingTime3 = 0;
BpodSystem.Data.ProcessingTime4 = 0;
BpodSystem.Data.ProcessingTime = 0;
BpodSystem.Data.ConfidenceReport=S.GUI.ConfidenceReport;
BpodSystem.Data.WTlimitLow=S.GUI.WTlimitLow;
BpodSystem.Data.WTlimitHigh=S.GUI.WTlimitHigh;
BpodSystem.Data.WTDropOutPun=S.GUI.WTDropOutPun;

%% Initialize Live Display Plot
BpodSystem.GUIHandles.LiveDispFig = figure('Position',[900 450 1000 600],'name','Live session display','numbertitle','off','MenuBar','none','Resize','off');
ha = axes('units','normalized', 'position',[0 0 1 1]);
uistack(ha,'bottom');
BG = imread('LiveSessionDataBG.bmp');
image(BG); axis off;

%% Initialize Outcome Plots (psychometric and sampling duration)
BpodSystem.GUIHandles.OutcomePlot = axes('Position', [0.075 0.66 0.9 0.25],'TickDir','out','YColor',[1 1 1],'XColor',[1 1 1],'FontSize',6);
OutcomePlot(BpodSystem.GUIHandles.OutcomePlot,'init',(TrialTypes==1)');

%% Psychometric Plot
BpodSystem.GUIHandles.LivePlot1 = axes('position',[0.07  0.20  0.42  0.375],'TickDir','out','YColor',[1 1 1],'XColor',[1 1 1],'FontSize',6);
plot([0 0],[0 1],'-k');hold on
plot([-1.7 1.7],[0.5 0.5],'-k');
text(0.5,0.2,['Left Choices Rewarded: ',num2str(0),'%'],'FontSize',8,'Color','k');
text(0.5,0.15,['Right Choices Rewarded: ',num2str(0),'%'],'FontSize',8,'Color','k');
plot(0,0,'-b','LineWidth',2.5);
errorbar(0,0,0,'-b','LineWidth',0.5);
plot(0,0,'-g','LineWidth',2.5);
errorbar(0,0,0,'-g','LineWidth',0.5);
xlim([-1.7 1.7]);xlim manual;
ylim([0 1]);ylim manual;
set(BpodSystem.GUIHandles.LivePlot1,'XTickLabelMode','manual');
set(BpodSystem.GUIHandles.LivePlot1,'XTickMode','manual');
set(BpodSystem.GUIHandles.LivePlot1,'YTickLabelMode','manual');
set(BpodSystem.GUIHandles.LivePlot1,'YTickMode','manual');
set(BpodSystem.GUIHandles.LivePlot1,'Box','off');
set(BpodSystem.GUIHandles.LivePlot1,'Tickdir','out');
Plot1Attribs = get(BpodSystem.GUIHandles.LivePlot1);
set(Plot1Attribs.Title,'String','log(R/L)','FontSize',8,'Color','w','FontName','arial','fontweight','bold');
set(Plot1Attribs.YLabel,'String','Right Choice(blue) / CorrectRewarded(green)','FontSize',8,'Color','w','FontName','arial','fontweight','bold');

%% Sampling Distribution Plot
BpodSystem.GUIHandles.LivePlot2 = axes('position',[0.56  0.20  0.42  0.375],'TickDir','out','YColor',[1 1 1],'XColor',[1 1 1],'FontSize',6);
plot([0.2 0.2],[0 1],'--k','LineWidth',1);hold on
text(0.01,0.25,['Sampling Duration: ',num2str(0),'ms'],'FontSize',8,'Color','k');
text(0.01,0.2,['Left Sampling DropOuts: ',num2str(0),'%'],'FontSize',8,'Color','k');
text(0.01,0.15,['Right Sampling DropOuts: ',num2str(0),'%'],'FontSize',8,'Color','k');
plot(0,0,'-b','LineWidth',2);
xlim([0 0.4]);xlim manual;
ylim([0 1]);ylim manual;
set(BpodSystem.GUIHandles.LivePlot2,'XTickLabelMode','manual');
set(BpodSystem.GUIHandles.LivePlot2,'XTickMode','manual');
set(BpodSystem.GUIHandles.LivePlot2,'YTickLabelMode','manual');
set(BpodSystem.GUIHandles.LivePlot2,'YTickMode','manual');
set(BpodSystem.GUIHandles.LivePlot2,'Box','off');
set(BpodSystem.GUIHandles.LivePlot2,'Tickdir','out');
Plot2Attribs = get(BpodSystem.GUIHandles.LivePlot2);
set(Plot2Attribs.Title, 'String', 'SamplingDuration (s)', 'FontSize', 8, 'Color', 'w', 'FontName', 'arial', 'fontweight', 'bold');
set(Plot2Attribs.YLabel, 'String', 'P(Sampling Duration)', 'FontSize', 8, 'Color', 'w', 'FontName', 'arial', 'fontweight', 'bold');

%% Initialize Rest of Outcome Plots
pause(0.5)
BpodSystem.GUIHandles.ProtocolNameDisplay = uicontrol('Style','text','String',BpodSystem.CurrentProtocolName,'Position',[170 67 175 18],'FontWeight','bold','FontSize',10,'ForegroundColor',[1 1 1],'BackgroundColor',[.45 .45 .45]);
BpodSystem.GUIHandles.SubjectNameDisplay = uicontrol('Style', 'text', 'String', BpodSystem.GUIData.SubjectName, 'Position', [170 40 175 18], 'FontWeight', 'bold', 'FontSize', 10, 'ForegroundColor', [1 1 1], 'BackgroundColor', [.45 .45 .45]);
BpodSystem.GUIHandles.starttime = uicontrol('Style', 'text', 'String', BpodSystem.GUIData.SettingsFileName, 'Position', [170 13 175 18], 'FontWeight', 'bold', 'FontSize', 10, 'ForegroundColor', [1 1 1], 'BackgroundColor', [.45 .45 .45]);
BpodSystem.GUIHandles.TrialNumberDisplay = uicontrol('Style','text','String','','Position',[520 67 105 18],'FontWeight','bold','FontSize',10,'ForegroundColor',[1 1 1],'BackgroundColor',[.44 .44 .44]);
BpodSystem.GUIHandles.TrialTypeDisplay = uicontrol('Style', 'text', 'String', '', 'Position', [520 40 105 18], 'FontWeight', 'bold', 'FontSize', 10, 'ForegroundColor', [1 1 1], 'BackgroundColor', [.44 .44 .44]);

%% Initialize Waiting Time Plots (WT distribution, WT Accuracy, WT Evidence)
BpodSystem.GUIHandles.LiveDispFigWT = figure('Position',[900 70 1000 450],'name','Confidence Report','numbertitle','off','MenuBar','none','Resize','off');

%% WT distribution Plot
BpodSystem.GUIHandles.LivePlot3 = axes('position',[0.05  0.05  0.275  0.65],'TickDir','out','YColor','k','XColor','k','FontSize',6);
plot([1 1],[0 1],'--k','LineWidth',1);hold on
plot([8 8],[0 1],'--k','LineWidth',1);
scatter(2,0.28,30,'MarkerFaceColor','g','MarkerEdgeColor','g');
line([2-1 2+1],[0.28 0.28],'Color','g','LineWidth',1,'LineStyle','-');
txt1 = 'RightChoiceCorrect';
text(6.5,0.28,txt1,'FontSize',6);
scatter(2,0.31,30,'MarkerFaceColor','g','MarkerEdgeColor','g');
line([2-1 2+1],[0.31 0.31],'Color','g','LineWidth',1,'LineStyle','-');
txt2 = 'LeftChoiceCorrect';
text(6.5,0.31,txt2,'FontSize',6);
scatter(2,0.34,30,'MarkerFaceColor','r','MarkerEdgeColor','r');
line([2-1 2+1],[0.34 0.34],'Color','r','LineWidth',1,'LineStyle','-');
txt3 = 'RightChoiceError';
text(6.5,0.34,txt3,'FontSize',6);
scatter(2,0.37,30,'MarkerFaceColor','r','MarkerEdgeColor','r');
line([2-1 2+1],[0.37 0.37],'Color','r','LineWidth',1,'LineStyle','-');
txt4 = 'LeftChoiceError';
text(6.5,0.37,txt4,'FontSize',6);
plot(0,0,'-g','LineWidth',2);
plot(0,0,'-r','LineWidth',2);
xlim([0 10]);xlim manual;
ylim([0 0.4]);ylim manual;
set(BpodSystem.GUIHandles.LivePlot3,'XTickLabelMode','manual');
set(BpodSystem.GUIHandles.LivePlot3,'XTickMode','manual');
set(BpodSystem.GUIHandles.LivePlot3,'YTickLabelMode','manual');
set(BpodSystem.GUIHandles.LivePlot3,'YTickMode','manual');
set(BpodSystem.GUIHandles.LivePlot3,'Box','off');
set(BpodSystem.GUIHandles.LivePlot3,'Tickdir','out');
Plot3Attribs = get(BpodSystem.GUIHandles.LivePlot3);
set(Plot3Attribs.Title, 'String', 'WaitingTime', 'FontSize', 8, 'Color', 'k', 'FontName', 'arial', 'fontweight', 'bold');
set(Plot3Attribs.YLabel, 'String', 'P(WT)', 'FontSize', 8, 'Color', 'k', 'FontName', 'arial', 'fontweight', 'bold');

%% WT accuracy Plot
BpodSystem.GUIHandles.LivePlot4 = axes('position',[0.385  0.05  0.275  0.65],'TickDir','out','YColor','k','XColor','k','FontSize',6);
plot([1 1],[0.4 1.1],'--k','LineWidth',1);hold on
plot([0 8],[0.5 0.5],'--k','LineWidth',1);
errorbar(0,0,0,'-b','LineWidth',2);
scatter(1.5,0.4,'MarkerFaceColor','k','MarkerEdgeColor','k');
text(1,1.05,'<meanWT','FontSize',6);
line([1.5 1.5],[0 0],'Color','k','LineWidth',2);
scatter(6.5,0.4,'MarkerFaceColor','k','MarkerEdgeColor','k');
text(6,1.05,'>meanWT','FontSize',6);
line([6.5 6.5],[0 0],'Color','k','LineWidth',2);
xlim([0 10]);xlim manual;
ylim([0.4 1.1]);ylim manual;
set(BpodSystem.GUIHandles.LivePlot4,'XTickLabelMode','manual');
set(BpodSystem.GUIHandles.LivePlot4,'XTickMode','manual');
set(BpodSystem.GUIHandles.LivePlot4,'YTickLabelMode','manual');
set(BpodSystem.GUIHandles.LivePlot4,'YTickMode','manual');
set(BpodSystem.GUIHandles.LivePlot4,'Box','off');
set(BpodSystem.GUIHandles.LivePlot4,'Tickdir','out');
Plot4Attribs = get(BpodSystem.GUIHandles.LivePlot4);
set(Plot4Attribs.Title, 'String', 'Waiting Time (s)', 'FontSize', 8, 'Color', 'k', 'FontName', 'arial', 'fontweight', 'bold');
set(Plot4Attribs.YLabel, 'String', 'Accuracy', 'FontSize', 8, 'Color', 'k', 'FontName', 'arial', 'fontweight', 'bold');

%% Confidence Plot
BpodSystem.GUIHandles.LivePlot5 = axes('position',[0.72  0.05  0.275  0.65],'TickDir','out','YColor','k','XColor','k','FontSize',6);
line([0 0],[0 8],'LineStyle','--','Color','k');hold on;
line([-1.7 1.7],[1 1],'LineStyle','--','Color','k');
line([-1.7 1.7],[8 8],'LineStyle','--','Color','k');
plot(0,0,'-r','LineWidth',2);
plot(0,0,'-g','LineWidth',2);
scatter(0,0,10,'o','MarkerFaceColor','r','MarkerEdgeColor','r');
scatter(0,0,10,'o','MarkerFaceColor','g','MarkerEdgeColor','g');
scatter(0,0,10,'o','MarkerFaceColor',[1 1 1],'MarkerEdgeColor','r');

text('String',['Current Trial: ',num2str(0)]);
TempHandle=get(BpodSystem.GUIHandles.LivePlot5);
set(TempHandle.Children(1),'Position',[-10 14]);
set(TempHandle.Children(1),'FontName','Arial','FontSize',10,'FontWeight','Bold');
set(TempHandle.Children(1),'horizontalAlignment','left');

text('String',['Current ReadOuts for Trials: ',num2str(0),' to ',num2str(0)]);
TempHandle=get(BpodSystem.GUIHandles.LivePlot5);
set(TempHandle.Children(1),'Position',[-10 13.5]);
set(TempHandle.Children(1),'FontName','Arial','FontSize',8);
set(TempHandle.Children(1),'horizontalAlignment','left');

text('String',['RewGivenLeft (µl): ',num2str(0)]);
TempHandle=get(BpodSystem.GUIHandles.LivePlot5);
set(TempHandle.Children(1),'Position',[-7 14]);
set(TempHandle.Children(1),'FontName','Arial','FontSize',8);
set(TempHandle.Children(1),'horizontalAlignment','left');

text('String',['RewGivenRight (µl): ',num2str(0)]);
TempHandle=get(BpodSystem.GUIHandles.LivePlot5);
set(TempHandle.Children(1),'Position',[-7 13.5]);
set(TempHandle.Children(1),'FontName','Arial','FontSize',8);
set(TempHandle.Children(1),'horizontalAlignment','left');

text('String',['Choice Bias: ',num2str(0)]);
TempHandle=get(BpodSystem.GUIHandles.LivePlot5);
set(TempHandle.Children(1),'Position',[-4 14]);
set(TempHandle.Children(1),'FontName','Arial','FontSize',8);
set(TempHandle.Children(1),'horizontalAlignment','left');

text('String',['Reward Bias (µl): ',num2str(0)]);
TempHandle=get(BpodSystem.GUIHandles.LivePlot5);
set(TempHandle.Children(1),'Position',[-4 13.5]);
set(TempHandle.Children(1),'FontName','Arial','FontSize',8);
set(TempHandle.Children(1),'horizontalAlignment','left');

text('String',['Left reward (µl): ',num2str(0)]);
TempHandle=get(BpodSystem.GUIHandles.LivePlot5);
set(TempHandle.Children(1),'Position',[-4 13]);
set(TempHandle.Children(1),'FontName','Arial','FontSize',8);
set(TempHandle.Children(1),'horizontalAlignment','left');

text('String',['Right reward (µl): ',num2str(0)]);
TempHandle=get(BpodSystem.GUIHandles.LivePlot5);
set(TempHandle.Children(1),'Position',[-4 12.5]);
set(TempHandle.Children(1),'FontName','Arial','FontSize',8);
set(TempHandle.Children(1),'horizontalAlignment','left');

text('String',['ProcTime (s): ',num2str(0)]);
TempHandle=get(BpodSystem.GUIHandles.LivePlot5);
set(TempHandle.Children(1),'Position',[-7 12.5]);
set(TempHandle.Children(1),'FontName','Arial','FontSize',8);
set(TempHandle.Children(1),'horizontalAlignment','left');

text('String',['Correct Catch Trials g(g): ',num2str(0)]);
TempHandle=get(BpodSystem.GUIHandles.LivePlot5);
set(TempHandle.Children(1),'Position',[-1 14]);
set(TempHandle.Children(1),'FontName','Arial','FontSize',8);
set(TempHandle.Children(1),'horizontalAlignment','left');

text('String',['Incorrect Catch Trials r(r): ',num2str(0)]);
TempHandle=get(BpodSystem.GUIHandles.LivePlot5);
set(TempHandle.Children(1),'Position',[-1 13.5]);
set(TempHandle.Children(1),'FontName','Arial','FontSize',8);
set(TempHandle.Children(1),'horizontalAlignment','left');

text('String',['Incorrect WT Trials r(): ',num2str(0)]);
TempHandle=get(BpodSystem.GUIHandles.LivePlot5);
set(TempHandle.Children(1),'Position',[-1 13]);
set(TempHandle.Children(1),'FontName','Arial','FontSize',8);
set(TempHandle.Children(1),'horizontalAlignment','left');

text('String',['CorrWTDropOutsLeft (%): ',num2str(0)]);
TempHandle=get(BpodSystem.GUIHandles.LivePlot5);
set(TempHandle.Children(1),'Position',[-1 12.5]);
set(TempHandle.Children(1),'FontName','Arial','FontSize',8);
set(TempHandle.Children(1),'horizontalAlignment','left');

text('String',['CorrWTDropOutsRight (%): ',num2str(0)]);
TempHandle=get(BpodSystem.GUIHandles.LivePlot5);
set(TempHandle.Children(1),'Position',[-1 12]);
set(TempHandle.Children(1),'FontName','Arial','FontSize',8);
set(TempHandle.Children(1),'horizontalAlignment','left');

xlim([-1.7 1.7]);xlim manual;
ylim([0 10]);ylim manual;
set(BpodSystem.GUIHandles.LivePlot5,'XTickLabelMode','manual');
set(BpodSystem.GUIHandles.LivePlot5,'XTickMode','manual');
set(BpodSystem.GUIHandles.LivePlot5,'YTickLabelMode','manual');
set(BpodSystem.GUIHandles.LivePlot5,'YTickMode','manual');
set(BpodSystem.GUIHandles.LivePlot5,'Box','off');
set(BpodSystem.GUIHandles.LivePlot5,'Tickdir','out');
Plot5Attribs = get(BpodSystem.GUIHandles.LivePlot5);
set(Plot5Attribs.Title, 'String', 'log(R/L)', 'FontSize', 8, 'Color', 'k', 'FontName', 'arial', 'fontweight', 'bold');
set(Plot5Attribs.YLabel, 'String', 'Waiting Time (s)', 'FontSize', 8, 'Color', 'k', 'FontName', 'arial', 'fontweight', 'bold');

%% Main trial loop
for currentTrial = 1:MaxTrials;
    
    if BpodSystem.BeingUsed==1;
        
        % Start of ProcessingTime1
        tic;
        
        S = BpodParameterGUI('sync', S); % Sync parameters with BpodParameterGUI plugin
        
        % Define ValveTimes/RewardAmounts (this is to counterbias sidebias)
        if currentTrial > 1;
            if S.GUI.RewardBias == 0 || BpodSystem.Data.ChoiceBias(currentTrial-1) == 0;
                BpodSystem.Data.RewardCounterBias(currentTrial) = 0;
                BpodSystem.Data.RewardAmountLeft(currentTrial) = S.GUI.RewardAmountLeft;
                BpodSystem.Data.RewardAmountRight(currentTrial) = S.GUI.RewardAmountRight;
                RL = GetValveTimes(BpodSystem.Data.RewardAmountLeft(currentTrial),1); % Update reward amounts
                RR = GetValveTimes(BpodSystem.Data.RewardAmountRight(currentTrial),3); % Update reward amounts
                LeftValveTime = RL;  % Update reward amounts
                RightValveTime = RR; % Update reward amounts
            else
                BpodSystem.Data.RewardCounterBias(currentTrial) = (abs(BpodSystem.Data.ChoiceBias(currentTrial-1))* ...
                    S.GUI.RewardBFactor) * ((S.GUI.RewardAmountLeft+S.GUI.RewardAmountRight)/2);
                if BpodSystem.Data.ChoiceBias(currentTrial-1) > 0;
                    BpodSystem.Data.RewardAmountLeft(currentTrial) = S.GUI.RewardAmountLeft - BpodSystem.Data.RewardCounterBias(currentTrial);
                    BpodSystem.Data.RewardAmountRight(currentTrial) = S.GUI.RewardAmountRight + BpodSystem.Data.RewardCounterBias(currentTrial);
                else
                    BpodSystem.Data.RewardAmountLeft(currentTrial) = S.GUI.RewardAmountLeft + BpodSystem.Data.RewardCounterBias(currentTrial);
                    BpodSystem.Data.RewardAmountRight(currentTrial) = S.GUI.RewardAmountRight - BpodSystem.Data.RewardCounterBias(currentTrial);
                end
                RL = GetValveTimes(BpodSystem.Data.RewardAmountLeft(currentTrial),1); % Update reward amounts
                RR = GetValveTimes(BpodSystem.Data.RewardAmountRight(currentTrial),3); % Update reward amounts
                LeftValveTime = RL;  % Update reward amounts
                RightValveTime = RR; % Update reward amounts
            end
        else
            BpodSystem.Data.RewardCounterBias(currentTrial) = 0;
            BpodSystem.Data.RewardAmountLeft(currentTrial) = S.GUI.RewardAmountLeft;
            BpodSystem.Data.RewardAmountRight(currentTrial) = S.GUI.RewardAmountRight;
            RL = GetValveTimes(BpodSystem.Data.RewardAmountLeft(currentTrial),1); % Update reward amounts
            RR = GetValveTimes(BpodSystem.Data.RewardAmountRight(currentTrial),3); % Update reward amounts
            LeftValveTime = RL;  % Update reward amounts
            RightValveTime = RR; % Update reward amounts
        end
        
        % Get the rates from the prior
        if currentTrial>40;
            omega = betarnd(S.GUI.Alpha,S.GUI.Alpha); % omega is drawn randomly from a beta distribution (with given alpha, 1 = flat)
        else
            omega = betarnd(S.GUI.Alpha/2,S.GUI.Alpha/2); % half difficulty for first 40 trials
        end
        
        % Establish if trials is catch trial and set proportion of 50/50 trials
        if currentTrial>0;  % CatchTrials from the beginning
            if rand<S.GUI.CatchTrialProbability
                CatchTrial = 1;
                if rand<S.GUI.ProportionCatchFifty50 % a certain proportion of catch trial of omega=0.5
                    omega = 0.5;
                end
            else
                CatchTrial = 0;
                if S.GUI.ProportionNormalFifty50~=0 && rand<S.GUI.ProportionNormalFifty50
                    omega = 0.5; % a certain proportion of normal trials with omega = 0.5
                end
            end
        else
            CatchTrial = 0;
        end
        
        % Establish the reward delay
        if CatchTrial==1
            RewardDelay = S.ProtocolSettings.CatchTrialRewardDelay; % Catch trials have a reward delay of 20s (maximum time that we wait for the rat)
        else
            % RewardDelay = TruncatedExponentialSample(S.GUI.MinimumRewardDelay,S.GUI.MaximumRewardDelay,S.GUI.ExponentRewardDelay); % waiting time that we define
            RewardDelayLeft = TruncatedExponentialSample(S.GUI.MinimumRewardDelayLeft,S.GUI.MaximumRewardDelayLeft,S.GUI.ExponentRewardDelayLeft); % waiting time that we define
            RewardDelayRight = TruncatedExponentialSample(S.GUI.MinimumRewardDelayRight,S.GUI.MaximumRewardDelayRight,S.GUI.ExponentRewardDelayRight); % waiting time that we define
        end
        
        % Shorter reward delay for early trials
        if currentTrial<20 && CatchTrial==0;
            % RewardDelay=RewardDelay/2;
            RewardDelayLeft=RewardDelayLeft/2;
            RewardDelayRight=RewardDelayRight/2;
        end
        
        % Generate the fast and slow click rates
        if omega>=0.5
            FastClickRate = omega*S.GUI.SumRates;
            SlowClickRate = (1-omega)*S.GUI.SumRates;
        else
            FastClickRate = (1-omega)*S.GUI.SumRates;
            SlowClickRate = omega*S.GUI.SumRates;
        end
        
        % Generate the fast and slow click trains
        FastClickTrain = GeneratePoissonClickTrain_PulsePal(FastClickRate,S.GUI.StimulusDuration*2); % Changed on 250717 to fix DoublePlayBug when using FixedStimulusDuration
        SlowClickTrain = GeneratePoissonClickTrain_PulsePal(SlowClickRate,S.GUI.StimulusDuration*2); % Changed on 250717 to fix DoublePlayBug when using FixedStimulusDuration
        
        % Ensure that click train are not empty and align first click
        if ~isempty(FastClickTrain) && ~isempty(SlowClickTrain);
            SlowClickTrain = SlowClickTrain-SlowClickTrain(1)+FastClickTrain(1);
        elseif isempty(SlowClickTrain) && ~isempty(FastClickTrain);
            SlowClickTrain = FastClickTrain(1);
        elseif isempty(FastClickTrain) && ~isempty(SlowClickTrain);
            FastClickTrain = SlowClickTrain(1);
        else
            FastClickTrain = 1/FastClickRate;
            SlowClickTrain = 1/SlowClickRate;
        end
        
        % Trial types and definition for reward and punishment
        switch TrialTypes(currentTrial); % Determine trial-specific state matrix fields
            case 1
                LeftActionState = 'WaitForRewardStart'; RightActionState = 'PunishStart';
                ValveCode = 1; ValveTime = LeftValveTime;
                SendCustomPulseTrain(2,FastClickTrain,ones(1,length(FastClickTrain))*5);
                SendCustomPulseTrain(1,SlowClickTrain,ones(1,length(SlowClickTrain))*5);
                if CatchTrial==0;
                    RewardDelay=RewardDelayLeft;
                end
            case 2
                LeftActionState = 'PunishStart'; RightActionState = 'WaitForRewardStart';
                ValveCode = 4; ValveTime = RightValveTime;
                SendCustomPulseTrain(2,SlowClickTrain,ones(1,length(SlowClickTrain))*5);
                SendCustomPulseTrain(1,FastClickTrain,ones(1,length(FastClickTrain))*5);
                if CatchTrial==0;
                    RewardDelay=RewardDelayRight;
                end
        end
        
        % Set the minimum sampling duration variable
        MinimumSamplingDuration = BpodSystem.Data.MinimumSamplingDuration(currentTrial);
        
        % We add here a random pre-stimulus delay (maximum 0.2 sec)
        StimulusDelayDuration = TruncatedExponentialSample(S.GUI.StimulusDelayMin,S.GUI.StimulusDelayMax,S.GUI.StimulusDelayExp);
        % StimulusDelayDuration = S.GUI.StimulusDelayDuration+S.GUI.StimulusRandDelayDuration*rand;
        
        % Define WireOutputAction for ResponseStart correct trials
        if (omega>0.875 && omega<=1)||(omega>0 && omega<=0.125);
            OutputActionsRespondStartCorrect=7; % Set wire outputs 1, 2 and 3 to "high"
        elseif (omega>0.750 && omega<=0.875)||(omega>0.125 && omega<=0.250);
            OutputActionsRespondStartCorrect=6; % Set wire outputs 2 and 3 to "high"
        elseif (omega>0.625 && omega<=0.750)||(omega>0.250 && omega<=0.375);
            OutputActionsRespondStartCorrect=5; % Set wire outputs 1 and 3 to "high"
        elseif (omega>0.500 && omega<=0.625)||(omega>0.375 && omega<=0.500);
            OutputActionsRespondStartCorrect=4; % Set wire output 3 to "high"
        end
        
        % Define WireOutputAction for ResponseStart incorrect trials
        if (omega>0.875 && omega<=1)||(omega>0 && omega<=0.125);
            OutputActionsRespondStartInCorrect=15; % Set wire outputs 1, 2, 3 and 4 to "high"
        elseif (omega>0.750 && omega<=0.875)||(omega>0.125 && omega<=0.250);
            OutputActionsRespondStartInCorrect=14; % Set wire outputs 2, 3 and 4 to "high"
        elseif (omega>0.625 && omega<=0.750)||(omega>0.250 && omega<=0.375);
            OutputActionsRespondStartInCorrect=13; % Set wire outputs 1, 3 and 4 to "high"
        elseif (omega>0.500 && omega<=0.625)||(omega>0.375 && omega<=0.500);
            OutputActionsRespondStartInCorrect=12; % Set wire outputs 3 and 4 to "high"
        end
        
        % Defining the global Timers for the StateMatrix
        sma = NewStateMatrix();
        sma = SetGlobalTimer(sma,1,RewardDelay);
        sma = SetGlobalTimer(sma,2,S.GUI.MaxPortInTime);
        sma = SetGlobalTimer(sma,3,S.GUI.EarlyTimeOut);
        
        % Send individual TrialCount
        TrialDigits=dec2base(currentTrial,10)-'0';
        TrialDigits=[zeros(1,4-length(TrialDigits)),TrialDigits];
        TrialDigit1=TrialDigits(1);
        TrialDigit2=TrialDigits(2);
        TrialDigit3=TrialDigits(3);
        TrialDigit4=TrialDigits(4);
        
        % TRIALCOUNT STATE1
        sma = AddState(sma,'Name','TrialCount1',...
            'Timer',0.001+(0.001*TrialDigit1),...
            'StateChangeConditions',{'Tup','TrialCount1KIll'},...
            'OutputActions',{'BNCState',2});
        
        % TRIALCOUNT STATE1 KILL
        sma = AddState(sma,'Name','TrialCount1KIll',...
            'Timer',0.001,...
            'StateChangeConditions',{'Tup','TrialCount2'},...
            'OutputActions',{'BNCState',0});
        
        % TRIALCOUNT STATE2
        sma = AddState(sma,'Name','TrialCount2',...
            'Timer',0.001+(0.001*TrialDigit2),...
            'StateChangeConditions',{'Tup','TrialCount2Kill'},...
            'OutputActions',{'BNCState',2});
        
        % TRIALCOUNT STATE2 KILL
        sma = AddState(sma,'Name','TrialCount2Kill',...
            'Timer',0.001,...
            'StateChangeConditions',{'Tup','TrialCount3'},...
            'OutputActions',{'BNCState',0});
        
        % TRIALCOUNT STATE3
        sma = AddState(sma,'Name','TrialCount3',...
            'Timer',0.001+(0.001*TrialDigit3),...
            'StateChangeConditions',{'Tup','TrialCount3Kill'},...
            'OutputActions',{'BNCState',2});
        
        % TRIALCOUNT STATE3 KILL
        sma = AddState(sma,'Name','TrialCount3Kill',...
            'Timer',0.001,...
            'StateChangeConditions',{'Tup','TrialCount4'},...
            'OutputActions',{'BNCState',0});
        
        % TRIALCOUNT STATE4
        sma = AddState(sma,'Name','TrialCount4',...
            'Timer',0.001+(0.001*TrialDigit4),...
            'StateChangeConditions',{'Tup','TrialCount4Kill'},...
            'OutputActions',{'BNCState',2});
        
        % TRIALCOUNT STATE4 KILL
        sma = AddState(sma,'Name','TrialCount4Kill',...
            'Timer',0.001,...
            'StateChangeConditions',{'Tup','WaitForCenterPoke'},...
            'OutputActions',{'BNCState',0});
        
        % STATE 1: Wait for rat to poke in center port
        sma = AddState(sma,'Name','WaitForCenterPoke',...
            'Timer',0,...
            'StateChangeConditions',{'Port2In','Delay'},...
            'OutputActions',{}); % 255 stands for 100% brightness, 128 for 50% brightness, 'OutputActions',{'PWM2',128});
        
        % STATE 2: Delay after poke before stimulus starts
        sma = AddState(sma,'Name','Delay',...
            'Timer',StimulusDelayDuration,...
            'StateChangeConditions',{'Tup','DeliverStimulus','Port2Out','exit'},... % 'StateChangeConditions',{'Tup','DeliverStimulus','Port2Out','exit'},...
            'OutputActions',{});
        
        % STATE 3: Deliver the stimulus until minimum samplign time is reached
        sma = AddState(sma,'Name','DeliverStimulus',...
            'Timer',MinimumSamplingDuration,...
            'StateChangeConditions',{'Tup','StillSampling','Port2Out','EarlyWithdrawalKill'},...
            'OutputActions',{'BNCState',1,'WireState',1});
        
        % STATE 5: Kill sound if withdrew early
        sma = AddState(sma,'Name','EarlyWithdrawalKill',...
            'Timer',0.01,...
            'StateChangeConditions',{'Tup','EarlyWithdrawalKill2'},...
            'OutputActions',{'BNCState',0});
        
        % STATE 6: Kill sound if withdrew early 2 and play punishment sound
        sma=AddState(sma,'Name','EarlyWithdrawalKill2',...
            'Timer',0.005,...
            'StateChangeConditions',{'Tup','EarlyWithdrawal'},...
            'OutputActions',{'BNCState',1});
        
        % STATE 4: Carry on delivering the stimulus
        sma = AddState(sma,'Name','StillSampling',...
            'Timer',S.GUI.StimulusDuration-MinimumSamplingDuration,...
            'StateChangeConditions',{'Tup','WaitForResponseKill','Port2Out','WaitForResponseKill'},...
            'OutputActions',{'BNCState',1});
        
        % STATE 7: Early withdrawal punishment with sound only
        sma = AddState(sma,'Name','EarlyWithdrawal',...
            'Timer', 0.01,...
            'StateChangeConditions', {'Tup', 'exit'},...
            'OutputActions', {});
        
        % STATE 8: Kill sound if waiting for response
        sma = AddState(sma,'Name','WaitForResponseKill',...
            'Timer', 0.02,...
            'StateChangeConditions', {'Tup', 'WaitForResponseKill2'},...
            'OutputActions', {'BNCState',0});
        
        % STATE 11: Kill sound if waiting for reponse
        sma = AddState(sma,'Name','WaitForResponseKill2',...
            'Timer', 0.02,...
            'StateChangeConditions', {'Tup', 'WaitForResponse'},...
            'OutputActions', {'BNCState', 1});
        
        % STATE 12: Wait for the rat to poke into one of the response ports
        sma = AddState(sma, 'Name', 'WaitForResponse', ...
            'Timer', S.GUI.TimeForResponse,...
            'StateChangeConditions', {'Tup', 'exit', 'Port1In', LeftActionState, 'Port3In', RightActionState},...
            'OutputActions', {}); % 255 stands for 100% brightness, 128 for 50% brightness,'PWM1',64,'PWM3',64
        
        % STATE 14: If correct side, wait for the reward to be delivered (= ResponseStart for correct trials)
        sma = AddState(sma,'Name','WaitForRewardStart',...
            'Timer',0.02,...
            'StateChangeConditions',{'Tup','WaitForReward'},...
            'OutputActions',{'GlobalTimerTrig',1,'WireState',OutputActionsRespondStartCorrect});
        
        % STATE 15: If correct side, wait for the reward to be delivered
        sma = AddState(sma, 'Name', 'WaitForReward', ...
            'Timer', RewardDelay,...
            'StateChangeConditions', {'Tup','Reward','Port1Out','WaitForRewardGraceL','Port3Out','WaitForRewardGraceR','GlobalTimer1_End','Reward'},...
            'OutputActions', {});
        
        % STATE 17: If correct side, wait for the reward to be delivered
        sma = AddState(sma, 'Name', 'WaitForRewardGraceL', ...
            'Timer', S.GUI.RewardGrace,...
            'StateChangeConditions', {'Tup','exit','Port1In','WaitForReward','GlobalTimer1_End','Reward','Port3In','WaitForReward'},... % 310717 'StateChangeConditions', {'Tup','exit','Port1In','WaitForReward','GlobalTimer1_End','Reward','Port3In','exit'},...
            'OutputActions', {});
        
        % STATE 18: If correct side, wait for the reward to be delivered
        sma = AddState(sma, 'Name', 'WaitForRewardGraceR', ...
            'Timer', S.GUI.RewardGrace,...
            'StateChangeConditions', {'Tup','exit','Port3In','WaitForReward','GlobalTimer1_End','Reward','Port1In','WaitForReward'},... % 310717 'StateChangeConditions', {'Tup','exit','Port3In','WaitForReward','GlobalTimer1_End','Reward','Port1In','exit'},...
            'OutputActions', {});
        
        % STATE 16A1: If waited enough, reward gets delivered
        sma = AddState(sma, 'Name', 'Reward', ...
            'Timer', ValveTime,...
            'StateChangeConditions', {'Tup', 'exit'},...
            'OutputActions', {'ValveState',ValveCode,'WireState',8});
        
        % STATE 13: ResponseStart for incorrect trials
        sma = AddState(sma,'Name','PunishStart',...
            'Timer',0.02,...
            'StateChangeConditions',{'Tup','Punish'},...
            'OutputActions',{'GlobalTimerTrig',2,'WireState',OutputActionsRespondStartInCorrect});
        
        % STATE 19: Time out if wrong decision
        sma = AddState(sma, 'Name', 'Punish', ...
            'Timer',0.02,... % previously S.GUI.TimeoutDuration
            'StateChangeConditions', {'Tup', 'StillWaiting','Port1Out','PunishGraceL','Port3Out','PunishGraceR'},...
            'OutputActions', {});
        
        % STATE 20: Keep the trial going until rat pulls out of response port
        sma=AddState(sma,'Name','StillWaiting',...
            'Timer',S.GUI.MaxPortInTime,...
            'StateChangeConditions',{'Tup','PunishEndState','Port1Out','PunishGraceL','Port3Out','PunishGraceR','GlobalTimer2_End','PunishEndState'},...
            'OutputActions', {});
        
        % STATE 21: Grace period for left incorrect trials
        sma = AddState(sma, 'Name', 'PunishGraceL', ...
            'Timer', S.GUI.PunishGrace,...
            'StateChangeConditions', {'Tup','PunishEndState','Port1In','StillWaiting','GlobalTimer2_End','PunishEndState','Port3In','StillWaiting'},... % originally Tup was set to exit % 310717 'StateChangeConditions', {'Tup','PunishEndState','Port1In','StillWaiting','GlobalTimer2_End','PunishEndState','Port3In','PunishEndState'},...
            'OutputActions', {});
        
        % STATE 22: Grace period for right incorrect trials
        sma = AddState(sma, 'Name', 'PunishGraceR', ...
            'Timer', S.GUI.PunishGrace,...
            'StateChangeConditions', {'Tup','PunishEndState','Port3In','StillWaiting','GlobalTimer2_End','PunishEndState','Port1In','StillWaiting'},... % originally Tup was set to exit % 310717 'StateChangeConditions', {'Tup','PunishEndState','Port3In','StillWaiting','GlobalTimer2_End','PunishEndState','Port1In','PunishEndState'},...
            'OutputActions', {});
        
        % STATE 23: If correct side, wait for the reward to be delivered
        sma = AddState(sma, 'Name', 'PunishEndState', ...
            'Timer', 0.02,...
            'StateChangeConditions', {'Tup', 'exit'},...
            'OutputActions', {'WireState',2});
        
        % End of ProcessingTime1
        BpodSystem.Data.ProcessingTime1(currentTrial) = toc;
        
        % Run StateMachine
        SendStateMatrix(sma);
%       RawEvents = RunStateMatrix;
        RawEvents = TryRunStateMatrix;
        
        % Compute the data we need
        if ~isempty(fieldnames(RawEvents)) % If trial data was returned
            
            % Store first data that doesn't need computation
            BpodSystem.Data = AddTrialEvents(BpodSystem.Data,RawEvents); % Computes trial events from raw data
            BpodSystem.Data.RawEvents.Trial;
            
            % Play GraceEndIndicator Sound
            if (~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.WaitForResponse(1)) ...
                    && isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.Reward(1)));
                if S.GUI.GraceEndIndicator == 1;
                    ProgramPulsePal(PulsePalEarlyWithdrawal);
                    TriggerPulsePal('11');
                    pause(0.05);
                    ProgramPulsePal(OriginalPulsePalMatrix);
                end
            end
            
            % This is to give a punishment TimeOut WaitingTimeDropOut
            if S.GUI.WTDropOutPun>0;
                if (~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.WaitForReward(1)) ...
                        && isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.Reward(1)));
                    for kk=1:0.1:S.GUI.WTDropOutPun;
                        pause(0.1); % This is the timeout for WaitingTimeDropOuts
                        ProgramPulsePal(PulsePalEarlyWithdrawal);
                        TriggerPulsePal('11');
                        pause(0.05);
                    end
                    ProgramPulsePal(OriginalPulsePalMatrix);
                end
            end
            
            % This is to give a punishment TimeOut after wrong decision (it does not work within the state matrix)
            if ~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.Punish(1));
                pause(S.GUI.TimeoutDuration);
            end
            
            % Play the early withdrawal sound and give early withdrawal TimeOut
            if (~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.EarlyWithdrawalKill(1)) || isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.DeliverStimulus(1)));
                if S.GUI.PunSound == 1;
                    %% Changing peep sound to white noise after early withdrawal
                    % ProgramPulsePal(PulsePalEarlyWithdrawal);
                    % TriggerPulsePal('11');
                    NoiseWaveVoltages=randn(1,1000)*0.5; % 200ms white noise waveform
                    ProgramPulsePalParam(1,12,1); % Sets output channel 1 to use custom train 1
                    ProgramPulsePalParam(2,12,2); % Sets output channel 2 to use custom train 1
                    SendCustomWaveform(1,0.0002,NoiseWaveVoltages); % Uploads noise waveform. Samples are played at 5khz.
                    SendCustomWaveform(2,0.0002,NoiseWaveVoltages); % Uploads noise waveform. Samples are played at 5khz.
                    TriggerPulsePal('11'); % Soft-triggers channels 1 and 2
                    
                    pause(S.GUI.EarlyTimeOut); % This is the early withdrawal timeout
                    ProgramPulsePal(OriginalPulsePalMatrix);
                else
                    pause(S.GUI.EarlyTimeOut); % This is the early withdrawal timeout
                end
            end
            
            % Start of ProcessingTime2
            tic;
            
            % Update SettingsParameter from the GUI
            BpodSystem.Data.StimulusDelayDuration(currentTrial) = StimulusDelayDuration;
            BpodSystem.Data.StimulusDelayMin(currentTrial) = S.GUI.StimulusDelayMin;
            BpodSystem.Data.StimulusDelayMax(currentTrial) = S.GUI.StimulusDelayMax;
            BpodSystem.Data.StimulusDelayExp(currentTrial) = S.GUI.StimulusDelayExp;
            BpodSystem.Data.TrialSettings(currentTrial) = S; % Adds the settings used for the current trial to the Data struct (to be saved after the trial ends)
            BpodSystem.Data.TrialTypes(currentTrial) = TrialTypes(currentTrial); % Adds the trial type of the current trial to data
            BpodSystem.Data.FastClickRate(currentTrial) = FastClickRate; % Adds the value of fast click rate
            BpodSystem.Data.SlowClickRate(currentTrial) = SlowClickRate; % Adds the vlaue of slow click rate
            BpodSystem.Data.CatchTrial(currentTrial) = CatchTrial; % 1 if trial is a Catch trial, 0 otherwise
            BpodSystem.Data.Omega(currentTrial) = omega; % Adds the value of omega;
            BpodSystem.Data.RewardDelay(currentTrial) = RewardDelay; % Adds the reward delay
            BpodSystem.Data.RewardGrace(currentTrial) = S.GUI.RewardGrace;
            BpodSystem.Data.TimeForReponse(currentTrial) = S.GUI.TimeForResponse ; % Time after sampling for subject to respond (s)
            BpodSystem.Data.TimeoutDuration(currentTrial) = S.GUI.TimeoutDuration ; % Duration of punishment timeout (s)
            BpodSystem.Data.StimulusDuration(currentTrial) = S.GUI.StimulusDuration ; % Duration of the sound
            BpodSystem.Data.Alpha(currentTrial) = S.GUI.Alpha; % Alpha parameter of the prior beta distribution
            BpodSystem.Data.SumRates(currentTrial) = S.GUI.SumRates; % Sum of the firing rates
            BpodSystem.Data.CatchTrialProbability(currentTrial) = S.GUI.CatchTrialProbability; % Probability of having a catch trial
            BpodSystem.Data.MaxMinimumSamplingDuration(currentTrial) = S.GUI.MaxMinimumSamplingDuration; % max Minimum sampling duration to have a valid trial
            BpodSystem.Data.ProportionCatchFifty50(currentTrial) = S.GUI.ProportionCatchFifty50; % Proportion of catch trials with omega=0.5;
            BpodSystem.Data.ProportionNormalFifty50(currentTrial) = S.GUI.ProportionNormalFifty50; % Proportion of Normal trials with omega=0.5 (0 means sampled randomly);
            BpodSystem.Data.EarlyTimeOut(currentTrial) = S.GUI.EarlyTimeOut; % Timeout for early Withdrawal
            % BpodSystem.Data.MinimumRewardDelay(currentTrial) = S.GUI.MinimumRewardDelay; % Minimum value of reward delay
            % BpodSystem.Data.MaximumRewardDelay(currentTrial) = S.GUI.MaximumRewardDelay; % Cutoff for reward delay distribution
            % BpodSystem.Data.ExponentRewardDelay(currentTrial) = S.GUI.ExponentRewardDelay; % Time constant of reward delay distribution
            BpodSystem.Data.MinimumRewardDelayLeft(currentTrial) = S.GUI.MinimumRewardDelayLeft; % Minimum value of reward delay
            BpodSystem.Data.MaximumRewardDelayLeft(currentTrial) = S.GUI.MaximumRewardDelayLeft; % Cutoff for reward delay distribution
            BpodSystem.Data.ExponentRewardDelayLeft(currentTrial) = S.GUI.ExponentRewardDelayLeft; % Time constant of reward delay distribution
            BpodSystem.Data.MinimumRewardDelayRight(currentTrial) = S.GUI.MinimumRewardDelayRight; % Minimum value of reward delay
            BpodSystem.Data.MaximumRewardDelayRight(currentTrial) = S.GUI.MaximumRewardDelayRight; % Cutoff for reward delay distribution
            BpodSystem.Data.ExponentRewardDelayRight(currentTrial) = S.GUI.ExponentRewardDelayRight; % Time constant of reward delay distribution
            BpodSystem.Data.RewardGrace(currentTrial) = S.GUI.RewardGrace;
            BpodSystem.Data.PunishGrace(currentTrial) = S.GUI.PunishGrace;
            BpodSystem.Data.FastClickTrain{currentTrial} = FastClickTrain;
            BpodSystem.Data.SlowClickTrain{currentTrial} = SlowClickTrain;
            BpodSystem.Data.StartTrial(currentTrial) = S.GUI.AnalysisStart;
            BpodSystem.Data.EndTrial(currentTrial) = S.GUI.AnalysisEnd;
            BpodSystem.Data.ConfidenceReport = S.GUI.ConfidenceReport;
            BpodSystem.Data.WTlimitLow = S.GUI.WTlimitLow;
            BpodSystem.Data.WTlimitHigh = S.GUI.WTlimitHigh;
            BpodSystem.Data.WTDropOutPun(currentTrial) = S.GUI.WTDropOutPun;
            
            % Now compute sampling duration and update minumum one
            % Sampling duration
            if ~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.EarlyWithdrawal(1))
                % Early withdrwal
                SamplingDuration=BpodSystem.Data.RawEvents.Trial{currentTrial}.States.DeliverStimulus(2)-BpodSystem.Data.RawEvents.Trial{currentTrial}.States.DeliverStimulus(1);
            elseif ~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.StillSampling(1))
                % Normal withdrwal
                SamplingDuration=BpodSystem.Data.RawEvents.Trial{currentTrial}.States.StillSampling(2)-BpodSystem.Data.RawEvents.Trial{currentTrial}.States.DeliverStimulus(1);
            else
                SamplingDuration=0.05; % Dummy value for the first trial, if early withdrawal
            end
            
            % This is to check, if MinSamplingDuration can be increased
            WindowSize=S.ProtocolSettings.WindowSize; % Number of trials to check back
            Threshold=S.ProtocolSettings.Threshold; % Number of trials above threshold in the window
            StepSize=S.ProtocolSettings.StepSize; % Increase next MinSamplingDuration by StepSize
            
            SamplingDurationS=[BpodSystem.Data.SamplingDuration SamplingDuration];
            
            if currentTrial>WindowSize;
                Range=currentTrial-(WindowSize):currentTrial;
                OKTrial(Range)= ~isnan(SamplingDurationS(Range)) & SamplingDurationS(Range)>BpodSystem.Data.MinimumSamplingDuration(currentTrial);
                SamplingValue=mean(OKTrial(currentTrial-(WindowSize):currentTrial));
                if SamplingValue>Threshold;
                    MinimumSamplingDurationNew=min(S.GUI.MaxMinimumSamplingDuration,BpodSystem.Data.MinimumSamplingDuration(currentTrial)+StepSize);
                end
            else
                MinimumSamplingDurationNew=S.GUI.InitialMinimumSamplingDuration;
                OKTrial(currentTrial)=~isnan(SamplingDurationS(currentTrial)) & SamplingDurationS(currentTrial)>BpodSystem.Data.MinimumSamplingDuration(currentTrial);
                SamplingValue=mean(OKTrial(1:currentTrial));
                
            end
            
            % Adds the extra stuff
            BpodSystem.Data.SamplingDuration(currentTrial)=SamplingDuration;
            BpodSystem.Data.MinimumSamplingDuration(currentTrial+1)=MinimumSamplingDurationNew;
            BpodSystem.Data.nTrials=currentTrial;
            BpodSystem.Data.Threshold(currentTrial)=Threshold;
            BpodSystem.Data.WindowSize(currentTrial)=WindowSize;
            BpodSystem.Data.SamplingValue(currentTrial)=SamplingValue;
            
            % Adds the minimum sampling duration
            % Datafields(currentTrial); % Updates the data fields
            if BpodSystem.Data.SamplingDuration(currentTrial)>BpodSystem.Data.MinimumSamplingDuration(currentTrial);
                BpodSystem.Data.SampledTrial(currentTrial)=1;
            else
                BpodSystem.Data.SampledTrial(currentTrial)=0;
            end
            
            if ~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.WaitForRewardStart(1))
                BpodSystem.Data.CorrectSide(currentTrial)=1;
            else
                BpodSystem.Data.CorrectSide(currentTrial)=0;
            end
            
            if ~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.Punish(1))
                BpodSystem.Data.PunishedTrial(currentTrial)=1;
            else
                BpodSystem.Data.PunishedTrial(currentTrial)=0;
            end
            
            % Get the chosen side
            if TrialTypes(currentTrial)==1
                if ~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.Punish(1))
                    BpodSystem.Data.ChosenDirection(currentTrial)=2;
                elseif ~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.WaitForRewardStart(1))
                    BpodSystem.Data.ChosenDirection(currentTrial)=1;
                else
                    BpodSystem.Data.ChosenDirection(currentTrial)=3;
                end
            else
                if ~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.Punish(1))
                    BpodSystem.Data.ChosenDirection(currentTrial)=1;
                elseif ~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.WaitForRewardStart(1))
                    BpodSystem.Data.ChosenDirection(currentTrial)=2;
                else
                    BpodSystem.Data.ChosenDirection(currentTrial)=3;
                end
            end
            
            % Get the number of clicks
            FastOnes=FastClickTrain<=SamplingDuration;
            SlowOnes=SlowClickTrain<=SamplingDuration;
            BpodSystem.Data.NFastClick(currentTrial)=sum(FastOnes);
            BpodSystem.Data.NSlowClick(currentTrial)=sum(SlowOnes);
            
            % Get the side of clicks
            if TrialTypes(currentTrial)==1
                BpodSystem.Data.NLeftClick(currentTrial)=BpodSystem.Data.NFastClick(currentTrial);
                BpodSystem.Data.NRightClick(currentTrial)=BpodSystem.Data.NSlowClick(currentTrial);
            else
                BpodSystem.Data.NRightClick(currentTrial)=BpodSystem.Data.NFastClick(currentTrial);
                BpodSystem.Data.NLeftClick(currentTrial)=BpodSystem.Data.NSlowClick(currentTrial);
            end
            
            % Get Choice given click
            if BpodSystem.Data.NLeftClick(currentTrial)>BpodSystem.Data.NRightClick(currentTrial);
                BpodSystem.Data.MostClickSide(currentTrial)=1;
            elseif BpodSystem.Data.NRightClick(currentTrial)>BpodSystem.Data.NLeftClick(currentTrial);
                BpodSystem.Data.MostClickSide(currentTrial)=2;
            else BpodSystem.Data.MostClickSide(currentTrial)=randi(2);
            end
            if BpodSystem.Data.MostClickSide(currentTrial)==BpodSystem.Data.ChosenDirection(currentTrial)
                BpodSystem.Data.ChoiceGivenClick(currentTrial)=1;
            else
                BpodSystem.Data.ChoiceGivenClick(currentTrial)=0;
            end
            
            % Get completed Trials
            BpodSystem.Data.CompletedTrial(currentTrial)=(~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.WaitForReward(1)) || ~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.Punish(1)));
            
            % Get the 2 different types of correct catch Trials
            BpodSystem.Data.CompletedCatchTrial(currentTrial)=(BpodSystem.Data.CompletedTrial(currentTrial)==1 & BpodSystem.Data.CatchTrial(currentTrial)==1);
            BpodSystem.Data.CorrectCatchTrial_type1(currentTrial)=(BpodSystem.Data.CompletedCatchTrial(currentTrial)==1 & BpodSystem.Data.ChoiceGivenClick(currentTrial)==1);
            if (~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.WaitForRewardStart(1)) ...
                    && isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.Reward(1))) && ...
                    BpodSystem.Data.CompletedCatchTrial(currentTrial)==0;
                BpodSystem.Data.CorrectCatchTrial_type2(currentTrial)=1;
            else
                BpodSystem.Data.CorrectCatchTrial_type2(currentTrial)=0;
            end
            
            % Get the WaitingTime
            % Case, where rewarded
            if ~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.Reward(1))
                BpodSystem.Data.WaitingTime(currentTrial)=BpodSystem.Data.RawEvents.Trial{currentTrial}.States.Reward(1)-BpodSystem.Data.RawEvents.Trial{currentTrial}.States.WaitForRewardStart(1);
                % Case, where correct choice but pulled out early
            elseif ~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.WaitForRewardStart(1))
                BpodSystem.Data.WaitingTime(currentTrial)=BpodSystem.Data.RawEvents.Trial{currentTrial}.States.WaitForReward(end)-BpodSystem.Data.RawEvents.Trial{currentTrial}.States.WaitForRewardStart(1);
                % Cases where wrong and waited a while
            elseif ~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.StillWaiting(1))
                BpodSystem.Data.WaitingTime(currentTrial)=BpodSystem.Data.RawEvents.Trial{currentTrial}.States.StillWaiting(end)-BpodSystem.Data.RawEvents.Trial{currentTrial}.States.Punish(1);
                % Cases where wrong and pulled quickly
            elseif ~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.Punish(1))
                BpodSystem.Data.WaitingTime(currentTrial)=BpodSystem.Data.RawEvents.Trial{currentTrial}.States.Punish(end)-BpodSystem.Data.RawEvents.Trial{currentTrial}.States.Punish(1);
            else
                BpodSystem.Data.WaitingTime(currentTrial)=NaN;
            end
            
            % Set conditions to the correct catch that are analysed
            if BpodSystem.Data.ConfidenceReport==0;
                BpodSystem.Data.CorrectCatchTrial(currentTrial)=(BpodSystem.Data.CorrectCatchTrial_type1(currentTrial)==1);
            else
                BpodSystem.Data.CorrectCatchTrial(currentTrial)=(BpodSystem.Data.CorrectCatchTrial_type1(currentTrial)==1 | BpodSystem.Data.CorrectCatchTrial_type2(currentTrial)==1);
            end
            
            % Defining the incorrect catch trials
            BpodSystem.Data.IncorrectCatchTrial(currentTrial)=(BpodSystem.Data.CompletedCatchTrial(currentTrial)==1 & BpodSystem.Data.ChoiceGivenClick(currentTrial)==0);
            
            % Get correct WaitingTime Trials
            BpodSystem.Data.CorrectWaitingTimeTrials(currentTrial)=BpodSystem.Data.CorrectCatchTrial(currentTrial)==1 & ...
                BpodSystem.Data.WaitingTime(currentTrial)>BpodSystem.Data.WTlimitLow & ...
                BpodSystem.Data.WaitingTime(currentTrial)<BpodSystem.Data.WTlimitHigh;
            
            % Get incorrect WaitingTime Trials
            BpodSystem.Data.InCorrectWaitingTimeTrials(currentTrial)= ...
                (BpodSystem.Data.IncorrectCatchTrial(currentTrial)==1 |  ...
                ((BpodSystem.Data.PunishedTrial(currentTrial)==1 &  ...
                BpodSystem.Data.CompletedTrial(currentTrial)==1) &  ...
                BpodSystem.Data.ChoiceGivenClick(currentTrial)==0)) & ...
                BpodSystem.Data.WaitingTime(currentTrial)>BpodSystem.Data.WTlimitLow & ...
                BpodSystem.Data.WaitingTime(currentTrial)<BpodSystem.Data.WTlimitHigh;
            
            % Remove unnecessary variables from Data structure
            ConfidenceReport=BpodSystem.Data.ConfidenceReport;
            WTlimitLow=BpodSystem.Data.WTlimitLow;
            WTlimitHigh=BpodSystem.Data.WTlimitHigh;
            Fields2remove={'ConfidenceReport','WTlimitLow','WTlimitHigh'};
            BpodSystem.Data=rmfield(BpodSystem.Data,Fields2remove);
            
            % Get the stimulus difficulty
            BpodSystem.Data.RatioDiscri(currentTrial)=log10((BpodSystem.Data.NRightClick(currentTrial)./BpodSystem.Data.NLeftClick(currentTrial)));
            
            % This is to compute wheter it was a rewarded trial
            if (~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.WaitForRewardStart(1)) ...
                    && (~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.Reward(1))));
                BpodSystem.Data.RewardedTrial(currentTrial)=1;
            else
                BpodSystem.Data.RewardedTrial(currentTrial)=0;
            end
            
            % Get correct left and correct right trials
            BpodSystem.Data.CorrectLeft(currentTrial)=BpodSystem.Data.ChoiceGivenClick(currentTrial)==1 & BpodSystem.Data.ChosenDirection(currentTrial)==1;
            BpodSystem.Data.CorrectRight(currentTrial)=BpodSystem.Data.ChoiceGivenClick(currentTrial)==1 & BpodSystem.Data.ChosenDirection(currentTrial)==2;
            
            % Get error left and correct right trials
            BpodSystem.Data.ErrorLeft(currentTrial)=BpodSystem.Data.ChoiceGivenClick(currentTrial)==0 & BpodSystem.Data.ChosenDirection(currentTrial)==1;
            BpodSystem.Data.ErrorRight(currentTrial)=BpodSystem.Data.ChoiceGivenClick(currentTrial)==0 & BpodSystem.Data.ChosenDirection(currentTrial)==2;
            
            % Calculating Choice Bias
            RewardBiasWindow = S.GUI.RewardBWindow;
            if currentTrial > RewardBiasWindow;
                BpodSystem.Data.LeftBias(currentTrial)= ...
                    sum(BpodSystem.Data.ErrorLeft(currentTrial-RewardBiasWindow:currentTrial)) / ...
                    sum(BpodSystem.Data.MostClickSide(currentTrial-RewardBiasWindow:currentTrial)==2);
                BpodSystem.Data.RightBias(currentTrial)= ...
                    sum(BpodSystem.Data.ErrorRight(currentTrial-RewardBiasWindow:currentTrial)) / ...
                    sum(BpodSystem.Data.MostClickSide(currentTrial-RewardBiasWindow:currentTrial)==1);
                if isnan(BpodSystem.Data.LeftBias(currentTrial))==1;
                    BpodSystem.Data.LeftBias(currentTrial)=0;
                end
                if isnan(BpodSystem.Data.RightBias(currentTrial))==1;
                    BpodSystem.Data.RightBias(currentTrial)=0;
                end
                BpodSystem.Data.ChoiceBias(currentTrial)=BpodSystem.Data.LeftBias(currentTrial)-BpodSystem.Data.RightBias(currentTrial);
            else
                BpodSystem.Data.ChoiceBias(currentTrial)=0;
                BpodSystem.Data.LeftBias(currentTrial)=0;
                BpodSystem.Data.RightBias(currentTrial)=0;
            end
            
            % Counter Payment
            PaymentRate=0.25;
            CounterPayment = BpodSystem.Data.WaitingTime(currentTrial)*PaymentRate;
            if isnan(CounterPayment)==1;
                CounterPayment=0;
            end
            if currentTrial > 21;
                BpodSystem.Data.HumanCounter(currentTrial) = BpodSystem.Data.HumanCounter(currentTrial-1) - CounterPayment;
            else
                BpodSystem.Data.HumanCounter(currentTrial) = 0;
            end
            
            % Counter Gain
            CounterGain=1;
            if currentTrial > 21;
                if BpodSystem.Data.RewardedTrial(currentTrial) == 1;
                    BpodSystem.Data.HumanCounter(currentTrial) =  BpodSystem.Data.HumanCounter(currentTrial)+CounterGain;
                else
                    BpodSystem.Data.HumanCounter(currentTrial) =  BpodSystem.Data.HumanCounter(currentTrial);
                end
            else
                BpodSystem.Data.HumanCounter(currentTrial) = 0;
            end
            
            % Define the non-completed trials (= early withdrawal trials)
            BpodSystem.Data.NonCompleted(currentTrial)=(BpodSystem.Data.CompletedTrial(currentTrial)==0);
            
            % Define window for current trial read outs
            BpodSystem.Data.CurrentWindow(currentTrial) = 50;
            CurrentWindow=BpodSystem.Data.CurrentWindow(currentTrial);
            
            % Define Start and End trial for online anlysis
            StartTrial=BpodSystem.Data.StartTrial(currentTrial);
            if StartTrial==0 || StartTrial >= currentTrial || isnan(StartTrial)==1;
                StartTrial = 1;
            end
            BpodSystem.Data.StartTrial(currentTrial)=StartTrial;
            EndTrial=BpodSystem.Data.EndTrial(currentTrial);
            if EndTrial==0 || EndTrial > currentTrial || isnan(StartTrial)==1;
                EndTrial = currentTrial;
            end
            BpodSystem.Data.EndTrial(currentTrial)=EndTrial;
            
            % Current Sampling ReadOuts
            if currentTrial > CurrentWindow+1;
                if StartTrial == 1 && EndTrial == currentTrial;
                    BpodSystem.Data.CurrentEarlyWithdrawal(currentTrial)=nanmean(BpodSystem.Data.NonCompleted(EndTrial-CurrentWindow:EndTrial));
                    BpodSystem.Data.CurrentEarlyWithdrawalLeft(currentTrial)=round((sum(BpodSystem.Data.NonCompleted(EndTrial-CurrentWindow:EndTrial)==1 & ...
                        BpodSystem.Data.MostClickSide(EndTrial-CurrentWindow:EndTrial)==1)/ ...
                        sum(BpodSystem.Data.MostClickSide(EndTrial-CurrentWindow:EndTrial)==1))*100);
                    BpodSystem.Data.CurrentEarlyWithdrawalRight(currentTrial)=round((sum(BpodSystem.Data.NonCompleted(EndTrial-CurrentWindow:EndTrial)==1 & ...
                        BpodSystem.Data.MostClickSide(EndTrial-CurrentWindow:EndTrial)==2)/ ...
                        sum(BpodSystem.Data.MostClickSide(EndTrial-CurrentWindow:EndTrial)==2))*100);
                    BpodSystem.Data.CurrentSamplingDuration(currentTrial)=nanmean(BpodSystem.Data.SamplingDuration(EndTrial-CurrentWindow:EndTrial));
                    BpodSystem.Data.CurrentCorrectWTDropOuts(currentTrial)=round((sum(BpodSystem.Data.CorrectCatchTrial_type2(EndTrial-CurrentWindow:EndTrial))/ ...
                        sum(BpodSystem.Data.CorrectSide(EndTrial-CurrentWindow:EndTrial)))*100);
                    BpodSystem.Data.CurrentCorrectWTDropOutsLeft(currentTrial)= ...
                        round((sum(BpodSystem.Data.CorrectCatchTrial_type2(EndTrial-CurrentWindow:EndTrial)==1 & BpodSystem.Data.ChosenDirection(EndTrial-CurrentWindow:EndTrial)==1)/ ...
                        sum(BpodSystem.Data.CorrectSide(EndTrial-CurrentWindow:EndTrial) & BpodSystem.Data.ChosenDirection(EndTrial-CurrentWindow:EndTrial)==1))*100);
                    BpodSystem.Data.CurrentCorrectWTDropOutsRight(currentTrial)= ...
                        round((sum(BpodSystem.Data.CorrectCatchTrial_type2(EndTrial-CurrentWindow:EndTrial)==1 & BpodSystem.Data.ChosenDirection(EndTrial-CurrentWindow:EndTrial)==2)/ ...
                        sum(BpodSystem.Data.CorrectSide(EndTrial-CurrentWindow:EndTrial) & BpodSystem.Data.ChosenDirection(EndTrial-CurrentWindow:EndTrial)==2))*100);
                else
                    BpodSystem.Data.CurrentEarlyWithdrawal(currentTrial)=nanmean(BpodSystem.Data.NonCompleted(StartTrial:EndTrial));
                    BpodSystem.Data.CurrentEarlyWithdrawalLeft(currentTrial)=round((sum(BpodSystem.Data.NonCompleted(StartTrial:EndTrial)==1 & ...
                        BpodSystem.Data.MostClickSide(StartTrial:EndTrial)==1)/ ...
                        sum(BpodSystem.Data.MostClickSide(StartTrial:EndTrial)==1))*100);
                    BpodSystem.Data.CurrentEarlyWithdrawalRight(currentTrial)=round((sum(BpodSystem.Data.NonCompleted(StartTrial:EndTrial)==1 & ...
                        BpodSystem.Data.MostClickSide(StartTrial:EndTrial)==2)/ ...
                        sum(BpodSystem.Data.MostClickSide(StartTrial:EndTrial)==2))*100);
                    BpodSystem.Data.CurrentSamplingDuration(currentTrial)=nanmean(BpodSystem.Data.SamplingDuration(StartTrial:EndTrial));
                    BpodSystem.Data.CurrentCorrectWTDropOuts(currentTrial)=round((sum(BpodSystem.Data.CorrectCatchTrial_type2(StartTrial:EndTrial))/ ...
                        sum(BpodSystem.Data.CorrectSide(StartTrial:EndTrial)))*100);
                    BpodSystem.Data.CurrentCorrectWTDropOutsLeft(currentTrial)= ...
                        round((sum(BpodSystem.Data.CorrectCatchTrial_type2(StartTrial:EndTrial)==1 & BpodSystem.Data.ChosenDirection(StartTrial:EndTrial)==1)/ ...
                        sum(BpodSystem.Data.CorrectSide(StartTrial:EndTrial) & BpodSystem.Data.ChosenDirection(StartTrial:EndTrial)==1))*100);
                    BpodSystem.Data.CurrentCorrectWTDropOutsRight(currentTrial)= ...
                        round((sum(BpodSystem.Data.CorrectCatchTrial_type2(StartTrial:EndTrial)==1 & BpodSystem.Data.ChosenDirection(StartTrial:EndTrial)==2)/ ...
                        sum(BpodSystem.Data.CorrectSide(StartTrial:EndTrial) & BpodSystem.Data.ChosenDirection(StartTrial:EndTrial)==2))*100);
                end
            else
                BpodSystem.Data.CurrentEarlyWithdrawal(currentTrial)=0;
                BpodSystem.Data.CurrentEarlyWithdrawalLeft(currentTrial)=0;
                BpodSystem.Data.CurrentEarlyWithdrawalRight(currentTrial)=0;
                BpodSystem.Data.CurrentSamplingDuration(currentTrial)=0;
                BpodSystem.Data.CurrentCorrectWTDropOuts(currentTrial)=0;
                BpodSystem.Data.CurrentCorrectWTDropOutsLeft(currentTrial)=0;
                BpodSystem.Data.CurrentCorrectWTDropOutsRight(currentTrial)=0;
            end
            
            % Calculate total amount of reward given so far in µl
            if currentTrial >= 2;
                if  BpodSystem.Data.RewardedTrial(currentTrial) == 1 && BpodSystem.Data.ChosenDirection(currentTrial) == 1;
                    BpodSystem.Data.TotalRewardGiven(currentTrial)=BpodSystem.Data.TotalRewardGiven(currentTrial-1)+BpodSystem.Data.RewardAmountLeft(currentTrial);
                    BpodSystem.Data.TotalRewardGivenLeft(currentTrial)=BpodSystem.Data.TotalRewardGivenLeft(currentTrial-1)+BpodSystem.Data.RewardAmountLeft(currentTrial);
                    BpodSystem.Data.TotalRewardGivenRight(currentTrial)=BpodSystem.Data.TotalRewardGivenRight(currentTrial-1);
                elseif BpodSystem.Data.RewardedTrial(currentTrial) == 1 && BpodSystem.Data.ChosenDirection(currentTrial) == 2;
                    BpodSystem.Data.TotalRewardGiven(currentTrial)=BpodSystem.Data.TotalRewardGiven(currentTrial-1)+BpodSystem.Data.RewardAmountRight(currentTrial);
                    BpodSystem.Data.TotalRewardGivenLeft(currentTrial)=BpodSystem.Data.TotalRewardGivenLeft(currentTrial-1);
                    BpodSystem.Data.TotalRewardGivenRight(currentTrial)=BpodSystem.Data.TotalRewardGivenRight(currentTrial-1)+BpodSystem.Data.RewardAmountRight(currentTrial);
                else
                    BpodSystem.Data.TotalRewardGiven(currentTrial)=BpodSystem.Data.TotalRewardGiven(currentTrial-1);
                    BpodSystem.Data.TotalRewardGivenLeft(currentTrial)=BpodSystem.Data.TotalRewardGivenLeft(currentTrial-1);
                    BpodSystem.Data.TotalRewardGivenRight(currentTrial)=BpodSystem.Data.TotalRewardGivenRight(currentTrial-1);
                end
            else
                if BpodSystem.Data.RewardedTrial(currentTrial) == 1 && BpodSystem.Data.ChosenDirection(currentTrial) == 1;
                    BpodSystem.Data.TotalRewardGiven(currentTrial)=BpodSystem.Data.RewardAmountLeft(currentTrial);
                    BpodSystem.Data.TotalRewardGivenLeft(currentTrial)=BpodSystem.Data.RewardAmountLeft(currentTrial);
                    BpodSystem.Data.TotalRewardGivenRight(currentTrial)=0;
                elseif BpodSystem.Data.RewardedTrial(currentTrial) == 1 && BpodSystem.Data.ChosenDirection(currentTrial) == 2;
                    BpodSystem.Data.TotalRewardGiven(currentTrial)=BpodSystem.Data.RewardAmountRight(currentTrial);
                    BpodSystem.Data.TotalRewardGivenLeft(currentTrial)=0;
                    BpodSystem.Data.TotalRewardGivenRight(currentTrial)=BpodSystem.Data.RewardAmountRight(currentTrial);
                else
                    BpodSystem.Data.TotalRewardGiven(currentTrial)=BpodSystem.Data.TotalRewardGiven(currentTrial);
                    BpodSystem.Data.TotalRewardGivenRight(currentTrial)=0;
                    BpodSystem.Data.TotalRewardGivenLeft(currentTrial)=0;
                end
            end
            
            % End of ProcessingTime2
            BpodSystem.Data.ProcessingTime2(currentTrial) = toc;
            
            % Pre-defining ProcessingTime3, 4 and Total
            BpodSystem.Data.ProcessingTime3(currentTrial) = 0;
            BpodSystem.Data.ProcessingTime4(currentTrial) = 0;
            BpodSystem.Data.ProcessingTime(currentTrial) = 0;
            
            % Start of ProcessingTime3
            tic;
            
            % Create Data for certain trials (DataShort and DataShortPsycho)
            nfields=length(fieldnames(BpodSystem.Data));
            DataVariables=fieldnames(BpodSystem.Data);
            if currentTrial < CurrentWindow+1;
                DataShort=BpodSystem.Data;
                DataShortPsycho=BpodSystem.Data;
            else
                if StartTrial == 1 && EndTrial == currentTrial;
                    DataShort=BpodSystem.Data;
                    for i=[1:3,5:nfields];
                        if isstruct(BpodSystem.Data.(DataVariables{i})) == 0;
                            DataShortPsycho.(DataVariables{i})=BpodSystem.Data.(DataVariables{i})(EndTrial-CurrentWindow:EndTrial);
                        end
                    end
                    DataShortPsycho.(DataVariables{4})=length(DataShortPsycho.(DataVariables{1}));
                else
                    for i=[1:3,5:nfields];
                        if isstruct(BpodSystem.Data.(DataVariables{i})) == 0;
                            DataShort.(DataVariables{i})=BpodSystem.Data.(DataVariables{i})(StartTrial:EndTrial);
                            DataShortPsycho.(DataVariables{i})=BpodSystem.Data.(DataVariables{i})(StartTrial:EndTrial);
                        end
                    end
                    DataShort.(DataVariables{4})=length(DataShort.(DataVariables{1}));
                    DataShortPsycho.(DataVariables{4})=length(DataShort.(DataVariables{1}));
                end
            end
            
            % Update all the plots
            if strcmp(get(gcf,'Name'),'Live Params')==0;
                UpdateOutcomePlot(TrialTypes,BpodSystem.Data,WTlimitLow,WTlimitHigh);
                UpdatePsychoPlot(TrialTypes,DataShort);
                UpdateConfPlot(TrialTypes,BpodSystem.Data,DataShort,DataShortPsycho,ConfidenceReport,WTlimitLow,WTlimitHigh);
            end
            
            % End of ProcessingTime3
            BpodSystem.Data.ProcessingTime3(currentTrial) = toc;
            
            % Start of ProcessingTime4
            tic;
            
            % Save all the new data
            % SaveBpodSessionData; % Saves the field BpodSystem.Data to the current data file (100518 disabled saving to Dropbox)
            
            % End of ProcessingTime4
            BpodSystem.Data.ProcessingTime4(currentTrial) = toc;
            
            % This is for monitoring the MATLAB processing time
            BpodSystem.Data.ProcessingTime(currentTrial) =  ...
                BpodSystem.Data.ProcessingTime1(currentTrial)+BpodSystem.Data.ProcessingTime2(currentTrial)+ ...
                BpodSystem.Data.ProcessingTime3(currentTrial)+BpodSystem.Data.ProcessingTime4(currentTrial);
            
        end
        if BpodSystem.BeingUsed == 0;
            % Save all the new data
            SaveBpodSessionData; % Saves the field BpodSystem.Data to the current data file (100518 disabled saving to Dropbox)
        end
        if BpodSystem.Pause == 1;
            % Save all the new data
            SaveBpodSessionData; % Saves the field BpodSystem.Data to the current data file (100518 disabled saving to Dropbox)
        end
    end
end
end

% Outcome Plot
function UpdateOutcomePlot(TrialTypes,Data,WTlimitLow,WTlimitHigh)
global BpodSystem
Outcomes = zeros(1,Data.nTrials);
for x = 1:Data.nTrials;
    
    if Data.RewardedTrial(x)==1;
        % if ~isnan(Data.RawEvents.Trial{x}.States.Reward(1));
        Outcomes(x)=1;
        
    elseif (Data.PunishedTrial(x)==1 && Data.CompletedCatchTrial(x)==0) && ...
            (Data.WaitingTime(x) > WTlimitLow && Data.WaitingTime(x) < WTlimitHigh);
        % elseif ~isnan(Data.RawEvents.Trial{x}.States.Punish(1));
        Outcomes(x)=0;
        
    elseif (Data.PunishedTrial(x)==1 && Data.CompletedCatchTrial(x)==0) && ...
            Data.WaitingTime(x) < WTlimitLow || Data.WaitingTime(x) > WTlimitHigh;
        % elseif ~isnan(Data.RawEvents.Trial{x}.States.Punish(1));
        Outcomes(x)=-3;
        
    elseif Data.CompletedCatchTrial(x)==1 && Data.ChoiceGivenClick(x)==1;
        % elseif ~isnan(Data.RawEvents.Trial{x}.States.WaitForReward(1))
        Outcomes(x)=-1;
        
    elseif Data.CompletedCatchTrial(x)==1 && Data.ChoiceGivenClick(x)==0;
        Outcomes(x)=-2;
        
    elseif Data.CorrectCatchTrial_type2(x)==1;
        Outcomes(x)=2;
        
    else
        Outcomes(x) = 3;
    end
end
OutcomePlot(BpodSystem.GUIHandles.OutcomePlot,'update',Data.nTrials+1,mod(TrialTypes,2)',Outcomes);
end

% PM Plots
function UpdatePsychoPlot(~,DataShort) % ~ or TrialTypes
global BpodSystem

LiveDispFig = BpodSystem.GUIHandles.LiveDispFig;
LivePlot1 = BpodSystem.GUIHandles.LivePlot1;
LivePlot2 = BpodSystem.GUIHandles.LivePlot2;

% Psychometric Plot
figure(LiveDispFig);
subplot(LivePlot1);
psychometricplotSlim(DataShort,LivePlot1);

% SamplingDuration Histogram
figure(LiveDispFig);
subplot(LivePlot2);
samplingdistplotSlim(DataShort,LivePlot2);
end

% ML Plots
function UpdateConfPlot(~,Data,DataShort,DataShortPsycho,ConfidenceReport,WTlimitLow,WTlimitHigh)
global BpodSystem

LiveDispFigWT = BpodSystem.GUIHandles.LiveDispFigWT;
LivePlot3 = BpodSystem.GUIHandles.LivePlot3;
LivePlot4 = BpodSystem.GUIHandles.LivePlot4;
LivePlot5 = BpodSystem.GUIHandles.LivePlot5;

% WaitingTime Histogram
figure(LiveDispFigWT);
subplot(LivePlot3);
WaitingTimeHistPlotSlim(DataShort,LivePlot3,WTlimitLow,WTlimitHigh);

% Accuracy Plot
figure(LiveDispFigWT);
subplot(LivePlot4);
WaitingTimeAccuracyPlotSlim(DataShort,LivePlot4,WTlimitLow,WTlimitHigh);

% Confidence Plot
figure(LiveDispFigWT);
subplot(LivePlot5);
ConfidencePlotSlim(DataShort,LivePlot5,DataShortPsycho,Data,ConfidenceReport,WTlimitLow,WTlimitHigh);
end

function RawEvents = TryRunStateMatrix()

try
    RawEvents = RunStateMatrix;
catch
    disp('RunStateMatrix failed, trying again')
    RawEvents = TryRunStateMatrix;
end

end
