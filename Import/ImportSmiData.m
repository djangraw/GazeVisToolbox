function [events, thresholds] = ImportSmiData(eyeFilename,eventFilename,screenSize,thresholds)

% [events, thresholds] = ImportSmiData(eyeFilename,screenSize,params)
%
% Created 9/11/15 by DJ.
% Updated 9/14/15 by DJ - moved log import to another script.
% Updated 9/16/15 by DJ - switched all positions from size 2xN to Nx2.
% Updated 10/30/15 by DJ - switched to ReadSmiEvents for event detection.

% Declare defaults
if ~exist('eyeFilename','var') || isempty(eyeFilename)
    eyeFilename = 'DistractionTask_S1-Samples.txt';
end
if ~exist('screenSize','var') || isempty(screenSize)
    screenSize = [1280, 1024]; % highest available res in 3T-C
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
[samples0,messages] = ReadSmiSamples(eyeFilename);
pos_raw = samples0.POR;
dt = median(diff(samples0.tSample))/1e3; % convert from us to ms
PD_raw = samples0.PD;

%% detect outliers (and zeros)
isOutlier = any(pos_raw <= 0-thresholds.outlierDist,2) | pos_raw(:,1) > screenSize(1)+thresholds.outlierDist | ...
    pos_raw(:,2) > screenSize(2)+thresholds.outlierDist | any(pos_raw == 0,2);
% interpolate for now (so they don't mess up smoothing too much)
pos_raw(isOutlier,:) = interp1(samples0.tSample(~isOutlier),pos_raw(~isOutlier,:),samples0.tSample(isOutlier),'linear','extrap');

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
% vel = [zeros(1,size(pos,2)); diff(pos,[],1)]/dt;

% remove outliers
pos(isOutlier,:) = NaN;
% vel(isOutlier,:) = NaN;
PD_raw(isOutlier,:) = NaN;

% use SMI's fixations, saccades, and blinks
[events.fixation, events.saccade, events.blink, events.message] = ReadSmiEvents(eventFilename);

% add samples
events.samples.position = pos;
events.samples.time = samples0.tSample/1e3; % convert to from us to ms
events.samples.PD = PD_raw;
