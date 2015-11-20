function [events, thresholds,smiParams] = ImportSmiData_Engbert(eyeFilename,thresholds)

% [events, thresholds,smiParams] = ImportSmiData_Engbert(eyeFilename,screenSize,params)
%
% Created 9/11/15 by DJ.
% Updated 9/14/15 by DJ - moved log import to another script.
% Updated 9/16/15 by DJ - switched all positions from size 2xN to Nx2.
% Updated 10/30/15 by DJ - switched to ReadSmiEvents for event detection.
% Updated 11/20/15 by DJ - switched to ReadSmiSamples_custom, which
% eliminated the need for screenSize input. Also removed eventFilename
% input.

% Declare defaults
if ~exist('eyeFilename','var') || isempty(eyeFilename)
    eyeFilename = 'DistractionTask_S1-Samples.txt';
end
if ~exist('thresholds','var') || isempty(thresholds)
    thresholds = struct('outlierDist',100,'winLength',0,'minBlinkDur',0,'minIbi',50,'minSacDur',0,'minIsi',50,'velThresh',3);
else
    % all time-based thresholds are in ms
    if ~isfield(thresholds,'outlierDist'), thresholds.outlierDist = 100; end % width of gaussian for smoothing
    if ~isfield(thresholds,'winLength'), thresholds.winLength = 0; end % width of gaussian for smoothing
    if ~isfield(thresholds,'minBlinkDur'), thresholds.minBlinkDur = 0; end % shorter blinks will be eliminated
    if ~isfield(thresholds,'minIbi'), thresholds.minIbi = 50; end % blinks too close together will be combined
    if ~isfield(thresholds,'minSacDur'), thresholds.minSacDur = 0; end % shorter saccades will be eliminated
    if ~isfield(thresholds,'minIsi'), thresholds.minIsi = 50; end % saccades too close together will be combined
    if ~isfield(thresholds,'velThresh'), thresholds.velThresh = 3; end % multiple of median-based stddev velocity considered a saccade
end

% Import samples and messages
[samples0,messages,smiParams] = ReadSmiSamples_custom(eyeFilename);
screenSize = str2num(smiParams.Calibration.CalibrationArea);
pos_raw = [samples0.RPORXpx, samples0.RPORYpx];
dt = median(diff(samples0.Time))/1e3; % convert from us to ms
PD_raw = [samples0.RDiaXpx, samples0.RDiaYpx];

%% detect outliers (and zeros)
isOutlier = any(pos_raw <= 0-thresholds.outlierDist,2) | pos_raw(:,1) > screenSize(1)+thresholds.outlierDist | ...
    pos_raw(:,2) > screenSize(2)+thresholds.outlierDist | any(pos_raw == 0,2);
% interpolate for now (so they don't mess up smoothing too much)
pos_raw(isOutlier,:) = interp1(samples0.Time(~isOutlier),pos_raw(~isOutlier,:),samples0.Time(isOutlier),'linear','extrap');

%% Get smoothed position
% Use Engbert smoothing (not recommended)
% [pos,vel] = SmoothEyePos_Engbert(pos_raw,thresholds.winLength,dt);

% Smooth by convolving with Gaussian window
if thresholds.winLength == 0
    pos = pos_raw;
else
    pos(:,1) = SmoothData(pos_raw(:,1)',thresholds.winLength,'full')';
    pos(:,2) = SmoothData(pos_raw(:,2)',thresholds.winLength,'full')';
end
vel = [zeros(1,size(pos,2)); diff(pos,[],1)]/dt;

% remove outliers
pos(isOutlier,:) = NaN;
vel(isOutlier,:) = NaN;
PD_raw(isOutlier,:) = NaN;

% add samples
events.samples.position = pos;
events.samples.time = samples0.Time/1e3; % convert to from us to ms
events.samples.PD = PD_raw;

%% detect blinks
[iBlinkStart,iBlinkEnd,pos_adj] = GetBlinks_Engbert(pos,dt,thresholds.minBlinkDur,thresholds.minIbi);

% set velocity and pupil dilation during blinks to nan
vel_adj = vel;
PD_adj = PD_raw;
for i=1:numel(iBlinkStart)
    vel_adj(iBlinkStart(i):iBlinkEnd(i)-1,:) = NaN;
    PD_adj(iBlinkStart(i):iBlinkEnd(i)-1,:) = NaN;
end

%% detect saccades
[iSacStart,iSacEnd,eta] = GetSaccades_Engbert(vel_adj,dt,thresholds.minSacDur,thresholds.minIsi,thresholds.velThresh);
thresholds.eta = eta; % save thresholds to struct

%% detect fixations
[iFixStart,iFixEnd,fixPos] = GetFixations_Engbert(iSacStart,iSacEnd,iBlinkStart,iBlinkEnd,pos_adj);

%% Add eye events to events struct
events.samples.position = pos_adj;
events.samples.time = samples0.Time/1e3; % convert to from us to ms
events.samples.PD = PD_adj;

events.saccade.time_start = events.samples.time(iSacStart);
events.saccade.time_end = events.samples.time(iSacEnd);
events.saccade.position_start = events.samples.position(iSacStart,:);
events.saccade.position_end = events.samples.position(iSacEnd,:);

events.blink.time_start = events.samples.time(iBlinkStart);
events.blink.time_end = events.samples.time(iBlinkEnd);

events.fixation.time_start = events.samples.time(iFixStart);
events.fixation.time_end = events.samples.time(iFixEnd);
events.fixation.position = fixPos;

%% Add sync events
events.message.time = messages.tMessage/1e3; % convert to ms
events.message.text = messages.text;