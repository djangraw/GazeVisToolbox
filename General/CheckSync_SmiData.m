function delay = CheckSync_SmiData(data,syncEvents)

% Extracts and compares the sync event times according to the eye tracker
% and the EEG to check for consistency.
%
% delay = CheckSync_SmiData(data,syncEvents)
%
% NOTES:
% - Sync events are sent every couple of seconds from the eyelink (which
% records the time each was sent) to the EEG (which records the time it was
% received). 
% - Sync events will be used to translate eyelink times into EEG times for
% analysis.
%
% INPUTS:
% - data is an SMI-based data struct (or vector of structs).
% - syncEvents is a cell vector indicating what sync event names will start
% with.
%
% Created 6/14/10 by DJ - as part of CheckData.
% Updated 7/28/10 by DJ - made into its own program.
% Updated 7/29/10 by DJ - changed events field back to eyelink.
% Updated 12/6/13 by DJ - added delay output, cleaned up.
% Updated 2/11/14 by DJ - added multi-session support
% Updated 9/25/14 by DJ - added SYNC_CODES input
% Updated 10/22/14 by DJ - turned event check back on
% Updated 9/11/15 by DJ - Converted from NEDE to Smi version.
% Updated 9/15/15 by DJ - assumes times in ms instead of s.

if ~exist('syncEvents','var')
    syncEvents = [];
end

% Get sync events
[eye,psy] = GetSyncEvents_SmiData(data,syncEvents);

%% Make sure events are the same
if ~isequal(psy.name,eye.name) || ~isequal(psy.session,eye.session) % number of events that aren't in exactly the right spot
    error('Sync events don''t match up! Make sure file has been fully imported and all sync events were logged properly.');
else
    disp('All event types match. Checking timing...')
    delay = [diff(psy.time)-diff(eye.time); NaN]; % subtract the time between timestamps    
    delay(diff(psy.session)~=0) = NaN; % only include within-session delays
    % plot histogram
    subplot(2,1,1); cla;
    hist(delay);
    xlabel('Delay (Time Received - Time Sent) in ms')
    ylabel('# events')
    title('Event Timing Consistency Check');
    % plot delays over time in each session
    subplot(2,1,2); cla;
    sessions = unique(psy.session);
    for i=1:numel(sessions)
        iEvents = find(psy.session==sessions(i));
        delayTimes = eye.time(iEvents) - eye.time(iEvents(1));
        subplot(2,numel(sessions),numel(sessions)+i);
        plot(delayTimes/1000,delay(iEvents), '.');
        xlabel('Event send time (s)');
        if i==1
            ylabel('Delay (ms)');
        end
        title(data(i).params.filename,'interpreter','none');        
    end
    % print results
    fprintf('Mean absolute value of delay is %g ms\n', nanmean(abs(delay)));
end