function [iBlinkStart,iBlinkEnd,pos_adjusted] = GetBlinks_Engbert(pos,dt,minDur,minIbi)
% Find saccades in a way similar to the saccade detection in Engbert, 2006. 
%
% [iBlinkStart,iBlinkEnd,pos_adjusted] = GetBlinks_Engbert(pos,dt,minDur,minIbi)
%
% INPUTS:
% -pos is an Nx2 matrix indicating the (x,y) position at each of N samples.
% samples that are nan or zero will be considered blinks.
% -dt is the time between samples (in ms).
% -minDur is the minimum blink duration allowed (in ms). Shorter blinks
% will be ignored.
% -minIbi is the minimum inter-blink interval allowed (in ms). Blinks
% closer together than this will be combined.
% 
% OUTPUTS:
% -iBlinkStart is an M-element vector of samples where blinks start.
% -iBlinkEnd is an M-element vector of samples where blinks end.
% -pos_adjusted is an Nx2 matrix equal to pos but with blink samples set to
% NaN.
%
% Based on saccade detection algorithm outlined in:
% Engbert, R., & Mergenthaler, K. (2006). Microsaccades are triggered by
% low retinal image slip. Proceedings of the National Academy of Sciences
% of the United States of America, 103(18), 7192?7.
% doi:10.1073/pnas.0509557103 
%
% Created 9/11/15 by DJ.
% Updated 9/16/15 by DJ - switched from pos size 2xN to Nx2, allow nans.

% Declare defaults
if ~exist('minDur','var') || isempty(minDur)
    minDur = 6; % for E&M 2006's microsaccade detection
end
if ~exist('minIbi','var') || isempty(minIbi)
    minIbi = 50; % not specified in E&M?
end

% convert to samples using dt
minDur_samples = ceil(minDur/dt);
minIbi_samples = ceil(minIbi/dt);
fprintf('Blinks: minDur = %d samples, minIbi = %d samples\n',minDur_samples,minIbi_samples);

% find which are above threshold
isInBlink = all(isnan(pos) | pos==0, 2);

% get all saccades
iBlinkStart = find(diff(isInBlink)>0)+1;
iBlinkEnd = find(diff(isInBlink)<0)+1;

% add initial/final saccade markers, if need be
if isInBlink(1)
    iBlinkStart = [1; iBlinkStart];
end
if isInBlink(end)
    iBlinkEnd = [iBlinkEnd; length(isInBlink)];
end

% remove saccades not more than minDur in length
isTooShort = (iBlinkEnd-iBlinkStart) < minDur_samples;
iBlinkStart(isTooShort) = [];
iBlinkEnd(isTooShort) = [];

% combine saccades not more than minIsi apart
iTooClose = find((iBlinkStart(2:end)-iBlinkEnd(1:end-1)) < minIbi_samples);
iBlinkStart(iTooClose+1) = [];
iBlinkEnd(iTooClose) = [];

% adjust position in blinks to be NaNs
pos_adjusted = pos;
for i=1:numel(iBlinkStart)
    pos_adjusted(iBlinkStart(i):iBlinkEnd(i)-1,:) = NaN;
end