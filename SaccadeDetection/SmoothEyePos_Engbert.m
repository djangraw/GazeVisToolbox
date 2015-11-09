function [pos, vel] = SmoothEyePos_Engbert(pos_raw,winLength,dt)
% Get smooth eye position and velocity data as described by Engbert, 2006.
%
% [pos, vel] = SmoothEyePos_Engbert(pos_raw,winLength,dt)
%
% INPUTS:
% -pos_raw is an Nx2 matrix indicating the (x,y) position of the eye at
% each sample.
% -winLength is a scalar indicating the width of the window (in ms) that
% should be used for smoothing.
% -dt is the time between samples (in ms).
%
% OUTPUTS:
% -pos is an Nx2 matrix indicating the smoothed position.
% -vel is an Nx2 matrix is the smoothed velocity.
%
% Based on saccade detection algorithm outlined in:
% Engbert, R., & Mergenthaler, K. (2006). Microsaccades are triggered by
% low retinal image slip. Proceedings of the National Academy of Sciences
% of the United States of America, 103(18), 7192?7.
% doi:10.1073/pnas.0509557103 
%
% Created 9/10/15 by DJ.

% handle defaults
if ~exist('winLength','var') || isempty(winLength)
    winLength = 2;
end
if ~exist('dt','var') || isempty(dt)
    dt = 1;
end

if winLength == 0
    pos = pos_raw;
    vel = [zeros(1,size(pos_raw,2)); diff(pos_raw,[],1)];
else
    % find smoothed velocity vector by using a moving-average window.
    win = [ones(winLength,1); 0; -ones(winLength,1)];
    vel = conv2(pos_raw,win,'same')/((winLength^2+2)*dt); % not sure why it's ^2+2, but it seems to work at any winLength.

    % reconstruct smoothed position matrix
    velToAdd = [zeros(1,size(vel,2)); vel(1:end-1,:)]; % only include velocity starting at 2nd time point.
    pos = repmat(pos_raw(1,:),size(pos_raw,1),1) + dt*cumsum(velToAdd,1);
end