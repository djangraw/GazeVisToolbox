function data = UnifyTiming_PsyToSmi(data0,syncEvents,psyFields)

% data = UnifyTiming_PsyToSmi(data0,syncEvents,psyFields)
%
%
% Created 9/15/15 by DJ.

if ~exist('SyncEvents','var')
    syncEvents = [];
end
if ~exist('psyFields','var') || isempty(psyFields)
    psyFields = {'display','key','soundset','soundstart'};
end

% copy input dataset
data = data0;

% Get sync times
[eye,psy] = GetSyncEvents_SmiData(data,syncEvents);

% Interpolate to get timing fields
for i=1:numel(data)
    iSync = find(eye.session==i);
    for j=1:numel(psyFields)
        subfields = fieldnames(data(i).events.(psyFields{j}));
        timefields = subfields(strncmp('time',subfields,length('time')));
        for k=1:numel(timefields)
            data(i).events.(psyFields{j}).(timefields{k}) = interp1(psy.time(iSync), eye.time(iSync), ...
                data0(i).events.(psyFields{j}).(timefields{k}),'linear','extrap');
        end
    end
end