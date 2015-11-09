function [tBlinkStart,tBlinkEnd] = MatchBinocularBlinks(events)

% Find the start and end of times where winks in both eyes overlap.
%
% [tBlinkStart,tBlinkEnd] = MatchBinocularBlinks(events)
%
% Created 5/7/15 by DJ.
% Updated 9/24/15 by DJ - added monocular case

% Handle monocular case
if ~isfield(events.blink,'eye') || numel(unique(events.blink.eye))<2
    fprintf('Only monocular data found - returning that eye''s blink times.\n')
    tBlinkStart = events.blink.time_start;
    tBlinkEnd = events.blink.time_end;
    return
end

isLeft = events.blink.eye=='L';

tBlink_L = [events.blink.time_start(isLeft), events.blink.time_end(isLeft)];
tBlink_R = [events.blink.time_start(~isLeft), events.blink.time_end(~isLeft)];

tBlink = MatchBinocularFixations(tBlink_L, tBlink_R, nan(size(tBlink_L)), nan(size(tBlink_R)));
tBlinkStart = tBlink(:,1);
tBlinkEnd = tBlink(:,2);