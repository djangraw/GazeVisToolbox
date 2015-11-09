function [iFixStart,iFixEnd,fixPos] = GetFixations_Engbert(iSacStart,iSacEnd,iBlinkStart,iBlinkEnd,pos)

% Find fixations after getting blinks and saccades as described by Engbert, 2006. 
%
% [iFixStart,iFixEnd,fixPos] = GetFixations_Engbert(iSacStart,iSacEnd,iBlinkStart,iBlinkEnd,pos)
%
% INPUTS:
% -iSacStart is an N-element vector of samples where saccades start.
% -iSacEnd is an N-element vector of samples where saccades end.
% -iBlinkStart is an M-element vector of samples where blinks start.
% -iBlinkEnd is an M-element vector of samples where blinks end.
% -pos is a Px2 matrix indicating the (x,y) position at each of P samples.
%
% OUTPUTS:
% -iFixStart is a Q-element vector of samples where fixations start.
% -iFixEnd is a Q-element vector of samples where fixations end.
% -fixPos is a Qx2 matrix of the mean (x,y) position during each fixation.
%
% Created 9/11/15 by DJ.
% Updated 9/16/15 by DJ - switched from pos size 2xN to Nx2 (and transposed
%  fixPos to match).

% figure out which samples are in fixations (via process of elimination)
isInFix = true(size(pos,1),1);
for i=1:numel(iSacStart)
    isInFix(iSacStart(i):iSacEnd(i)-1) = false;
end
for i=1:numel(iBlinkStart)
    isInFix(iBlinkStart(i):iBlinkEnd(i)-1) = false;
end

% get all fixations
iFixStart = find(diff(isInFix)>0)+1;
iFixEnd = find(diff(isInFix)<0)+1;

% add initial/final fixation markers, if need be
if isInFix(1)
    iFixStart = [1; iFixStart];
end
if isInFix(end)
    iFixEnd = [iFixEnd; length(isInFix)];
end

% get average position in each fixation
fixPos = nan(numel(iFixStart),2);
for i=1:numel(iFixStart)
    fixPos(i,:) = mean(pos(iFixStart(i):iFixEnd(i)-1,:),1);
end