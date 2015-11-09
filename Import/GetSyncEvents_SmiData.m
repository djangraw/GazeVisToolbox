function [eye,psy] = GetSyncEvents_SmiData(data,SyncEvents)

% Gets the sync events from a NEDE eye position file and EEG file.
%
% [eye,psy] = GetSyncEvents_SmiData(data,SyncEvents)
%
% INPUTS:
% - data is an SMI-based data struct (or vector of structs).
% - SyncEvents is a cell vector indicating what sync event names will start
% with.
%
% OUTPUTS:
% -eye and psy are structs of the sync data from the eye tracker and
% psychopy log, respectively. Each contains fields time, name, and session.
%
% Created 2/11/14 by DJ.
% Updated 2/19/14 by DJ - comments.
% Updated 9/11/15 by DJ - Converted from NEDE to Smi version.

if nargin<3 || isempty(SyncEvents)
    % Set up
    SyncEvents = {'Fixation','Page'}; % numbers that NEDE sends to the EEG through the eye tracker
end

% Extract info from SMI messages
nSessions = length(data);
if nSessions>1
    [tim,num,sess] = deal(cell(1,nSessions));
    for i=1:nSessions
        tim{i} = data(i).events.message.time;
        num{i} = data(i).events.message.text;
        sess{i} = repmat(i,length(data(i).events.message.time),1);
    end
%     eye = struct('time',cat(1,tim{:}),'name',cat(1,num(:)),'session',cat(1,sess{:}));    
    eye.time = cat(1,tim{:});
    eye.name = cat(1,num{:});
    eye.session = cat(1,sess{:});
else
    % Extract info from the struct we made (for easier access)
%     eye = struct('time',data.events.message.time, 'name',data.events.message.text,'session',ones(length(data.events.message.time),1)); % times in ms
    eye.time = cat(1,data.events.message.time);
    eye.name = cat(1,data.events.message.text);
    eye.session = ones(length(data.events.message.time),1);
end


% Extract info from psychopy displays
if nSessions>1
    [tim,num,sess] = deal(cell(1,nSessions));
    for i=1:nSessions
        tim{i} = data(i).events.display.time;
        num{i} = data(i).events.display.name;
        sess{i} = repmat(i,length(data(i).events.display.time),1);
    end
%     psy = struct('time',cat(1,tim{:}),'name',cat(1,num(:)),'session',cat(1,sess{:}));    
    psy.time = cat(1,tim{:});
    psy.name = cat(1,num{:});
    psy.session = cat(1,sess{:});
    
else
    % Extract info from the struct we made (for easier access)
%     psy = struct('time',data.events.display.time, 'name',data.events.display.name,'session',ones(length(data.events.display.time),1)); % times in s
    psy.time = cat(1,data.events.display.time);
    psy.name = cat(1,data.events.display.name);
    psy.session = ones(length(data.events.display.time),1);
end


%% Crop to sync events
isSyncEvent = false(1,numel(eye.time));
for i=1:numel(SyncEvents)
    isSyncEvent(strncmp(['Display' SyncEvents{i}],eye.name,length(['Display' SyncEvents{i}]))) = true;
end
% crop all struct fields
eye = CropStruct(eye,isSyncEvent);
% get rid of leading 'Display' in each event name (to match psy struct)
for i=1:numel(eye.name)
    eye.name{i} = eye.name{i}((length('Display')+1):end); % crop out leading 'Display'
end

% do the same for psy struct
isSyncEvent = false(1,numel(psy.time));
for i=1:numel(SyncEvents)
    isSyncEvent(strncmp(SyncEvents{i},psy.name,length(SyncEvents{i}))) = true;
end
% crop all struct fields
psy = CropStruct(psy,isSyncEvent);
