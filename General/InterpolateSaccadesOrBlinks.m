function [samplesInterp, isInSacOrBlink] = InterpolateSaccadesOrBlinks(tSamples,samples,events,method,blinksonly)

% [samplesInterp, isInSacOrBlink] = InterpolateSaccadesOrBlinks(tSamples,samples,events,method,blinksonly)
%
% INPUTS:
% - tSamples is an n-element vector of times.
% - samples is an nxm array of position or pupil size values.
% - events is a reading data struct with subfields saccade.time_start/end
% and blink.time_start/end.
% - method is a string indicating the interpolation method (see interp1
% help for options).
% - blinksonly is a binary value indicating whether you want only blinks to
% be interpolated or whether it should be both blinks and saccades.
%
% OUTPUTS:
% - samplesInterp is an nxm array that is the same as samples but with
% samples inside a blink or saccade interpolated.
% - isInBlinkOrSac is an n-element binary vector in which the times that
% were interpolated are true.
%
% Created 5/8/15 by DJ.

% Handle defaults
if ~exist('method','var') || isempty(method)
    method = 'linear';
end
if ~exist('blinksonly','var') || isempty(blinksonly)
    blinksonly = false;
end


% find saccades
tSaccades = [events.saccade.time_start, events.saccade.time_end];
isInSacOrBlink = false(1,numel(tSamples));

if blinksonly
    % find blinks
    tBlinks = [events.blink.time_start, events.blink.time_end];    
    nBlinks = numel(events.blink.time_start);

    % find eye
    eBlinks = events.blink.eye;
    eSaccades = events.saccade.eye;
    
    % find sample times in blinks    
    for i=1:nBlinks
        % find surrounding saccade
        iSac = find(tSaccades(:,1)<tBlinks(i,1) & eSaccades==eBlinks(i),1,'last');        
        isInSacOrBlink(tSamples>tSaccades(iSac,1) & tSamples<tSaccades(i,2)) = true;
    end
else
    % set up
    nSaccades = numel(events.saccade.time_start);
    % find sample times in saccades    
    for i=1:nSaccades
        isInSacOrBlink(tSamples>tSaccades(i,1) & tSamples<tSaccades(i,2)) = true;
    end

end

% interpolate samples in either
samplesInterp = samples;
samplesInterp(isInSacOrBlink,:) = interp1(tSamples(~isInSacOrBlink), samples(~isInSacOrBlink,:), tSamples(isInSacOrBlink),method,'extrap');


