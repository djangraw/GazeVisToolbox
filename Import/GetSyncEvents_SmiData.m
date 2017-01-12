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
% Updated 1/15/16 by DJ - added DISPLAY_PREFIX, with added space after 'Display'
% Updated 7/26/16 by DJ - added CropStructsToMatch and recursive call to
% fix timing/sync issues

if nargin<3 || isempty(SyncEvents)
    % Set up
    SyncEvents = {'Fixation','Page'}; % numbers that NEDE sends to the EEG through the eye tracker
end
DISPLAY_PREFIX = 'Display '; % for EyeLink or post-2015 SMI files
% DISPLAY_PREFIX = 'Display'; % for pre-2016 SMI files

if length(data)>1
    % Call recursively for each session
    for i=1:numel(data)
        [eye0(i),psy0(i)] = GetSyncEvents_SmiData(data(i),SyncEvents);
        eye0(i).session(:) = i;
        psy0(i).session(:) = i;
    end
    % Append structs
    eye.time = cat(1,eye0(:).time);
    eye.name = cat(1,eye0(:).name);
    eye.session = cat(1,eye0(:).session);
    %     psy = struct('time',cat(1,tim{:}),'name',cat(1,num(:)),'session',cat(1,sess{:}));    
    psy.time = cat(1,psy0(:).time);
    psy.name = cat(1,psy0(:).name);
    psy.session = cat(1,psy0(:).session);
else
    % Extract info from data struct
    eye.time = data.events.message.time;
    eye.name = data.events.message.text;
    eye.session = ones(length(data.events.message.time),1);
    psy.time = data.events.display.time;
    psy.name = data.events.display.name;
    psy.session = ones(length(data.events.display.time),1);    

    %% Crop to sync events
    isSyncEvent = false(1,numel(eye.time));
    for i=1:numel(SyncEvents)
        isSyncEvent(strncmp([DISPLAY_PREFIX SyncEvents{i}],eye.name,length([DISPLAY_PREFIX SyncEvents{i}]))) = true;
    end
    % crop all struct fields
    eye = CropStruct(eye,isSyncEvent);
    % get rid of leading 'Display' in each event name (to match psy struct)
    for i=1:numel(eye.name)
        eye.name{i} = eye.name{i}((length(DISPLAY_PREFIX)+1):end); % crop out leading 'Display'
    end

    % do the same for psy struct
    isSyncEvent = false(1,numel(psy.time));
    for i=1:numel(SyncEvents)
        isSyncEvent(strncmp(SyncEvents{i},psy.name,length(SyncEvents{i}))) = true;
    end
    % crop all struct fields
    psy = CropStruct(psy,isSyncEvent);
    
    % Crop Structs to match, if possible
    [eye,psy] = CropStructsToMatch(eye,psy,'name');
end