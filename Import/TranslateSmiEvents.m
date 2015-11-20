function events = TranslateSmiEvents(eventsRaw,eyeTracked)

% Translate the SMI input to the format that GazeVisToolbox typically uses.
%
% events = TranslateSmiEvents(eventsRaw,eyeTracked)
%
% INPUTS:
% -eventsRaw is a struct from the output of ReadSmiEvents_custom.
% -eyeTracked is a character 'r' or 'l' for left or right eye tracked.
%
% OUTPUTS:
% -events is a struct with cropped and adjusted field and subfield names.
%
% Created 11/20/15 by DJ.

% Declare defaults
if ~exist('eyeTracked','var') || isempty(eyeTracked)
    eyeTracked = 'r';
end

% Translate fixation events
events.fixation.time_start = eventsRaw.Fixations.Start/1000; % convert from us to ms
events.fixation.time_end = eventsRaw.Fixations.End/1000; % convert from us to ms
events.fixation.position = [eventsRaw.Fixations.LocationX, eventsRaw.Fixations.LocationY]; % x,y
events.fixation.eye = repmat(eyeTracked,size(events.fixation.time_start));

% Translate saccade events
events.saccade.time_start = eventsRaw.Saccades.Start/1000; % convert from us to ms
events.saccade.time_end = eventsRaw.Saccades.End/1000; % convert from us to ms
events.saccade.position_start = [eventsRaw.Saccades.StartLocX, eventsRaw.Saccades.StartLocY]; % x,y
events.saccade.position_end = [eventsRaw.Saccades.EndLocX, eventsRaw.Saccades.EndLocY]; % x,y
events.saccade.eye = repmat(eyeTracked,size(events.saccade.time_start));

% Translate blink events
events.blink.time_start = eventsRaw.Blinks.Start/1000; % convert from us to ms
events.blink.time_end = eventsRaw.Blinks.End/1000; % convert from us to ms
events.blink.eye = repmat(eyeTracked,size(events.blink.time_start));

% Translate display events
events.message.time = eventsRaw.UserEvents.Start/1000; % convert from us to ms
events.message.text = eventsRaw.UserEvents.Description;
% remove prepending "# Message: "
for i=1:numel(events.message.text)
    events.message.text{i} = events.message.text{i}(length('# Message: ')+1:end);
end