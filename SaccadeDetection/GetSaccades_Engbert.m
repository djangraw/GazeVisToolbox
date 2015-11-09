function [iSacStart,iSacEnd,eta] = GetSaccades_Engbert(vel,dt,minDur,minIsi,velThresh)

% Find saccades as described by Engbert, 2006. 
%
% [iSacStart,iSacEnd,eta] = GetSaccades_Engbert(vel,dt,minDur,minIsi,velThresh)
%
% INPUTS:
% -vel is an Nx2 matrix indicating the (x,y) velocity at each of N samples.
% -dt is the time between samples (in ms).
% -minDur is the minimum saccade duration allowed (in ms). Shorter saccades
% will be ignored.
% -minIsi is the minimum inter-saccade interval allowed (in ms). Saccades
% closer together than this will be combined.
% -velThresh is the multiple of the median-based stddev velocity
% considered a saccade.
%
% OUTPUTS:
% -iSacStart is an M-element vector of samples where saccades start.
% -iSacEnd is an M-element vector of samples where saccades end.
% -eta is a 2-element vector of absolute velocity thresholds based on 
% velThresh and the velocity data'a median-based stddev.
%
% Based on saccade detection algorithm outlined in:
% Engbert, R., & Mergenthaler, K. (2006). Microsaccades are triggered by
% low retinal image slip. Proceedings of the National Academy of Sciences
% of the United States of America, 103(18), 7192?7.
% doi:10.1073/pnas.0509557103 
%
% Created 9/10/15 by DJ.
% Updated 9/16/15 by DJ - removed +1 from iSacStart declaration (saccades
%  were starting 1 sample too late)
% Updated 9/16/15 by DJ - switched from vel size 2xN to Nx2.

if ~exist('minDur','var') || isempty(minDur)
    minDur = 6; % for E&M 2006's microsaccade detection
end
if ~exist('minIsi','var') || isempty(minIsi)
    minIsi = 50; % not specified in E&M?
end
if ~exist('velThresh','var') || isempty(velThresh)
    velThresh = 5; % for E&M 2006's microsaccade detection
end

% convert to samples using dt
minDur_samples = ceil(minDur/dt);
minIsi_samples = ceil(minIsi/dt);
fprintf('Saccades: minDur = %d samples, minIsi = %d samples\n',minDur_samples,minIsi_samples);

% find absolute velocity thresholds
sigma = nan(size(vel,2),1);
for i=1:size(vel,2)
    sigma(i) = sqrt( nanmedian( (vel(:,i)-nanmedian(vel(:,i))).^2 ) );    
end
eta = sigma*velThresh;
for i=1:numel(eta)
    fprintf('eta(%d) = %.3g\n',i,eta(i));
end

% combine across x,y directions
velTotal = rssq(vel,2); % get total (root-sum-of-squares) velocity at each sample
etaTotal = rssq(eta);

% find which are above threshold
isAboveThresh = velTotal>etaTotal;

% get all saccades
iSacStart = find(diff(isAboveThresh)>0);
iSacEnd = find(diff(isAboveThresh)<0);

% add initial/final saccade markers, if need be
if isAboveThresh(1)
    iSacStart = [1; iSacStart];
end
if isAboveThresh(end)
    iSacEnd = [iSacEnd; length(isAboveThresh)];
end

% remove saccades not more than minDur in length
isTooShort = (iSacEnd-iSacStart) < minDur_samples;
iSacStart(isTooShort) = [];
iSacEnd(isTooShort) = [];

% combine saccades not more than minIsi apart
iTooClose = find((iSacStart(2:end)-iSacEnd(1:end-1)) < minIsi_samples);
iSacStart(iTooClose+1) = [];
iSacEnd(iTooClose) = [];