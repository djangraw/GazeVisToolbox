function eventsSplit = SplitSmiEventsStruct(eventsRaw,tBoundaries)

% eventsSplit = SplitSmiEventsStruct(eventsRaw,tBoundaries)
%
% Created 9/14/15 by DJ.

% handle no-split case
if isempty(tBoundaries)
    eventsSplit = eventsRaw;
    return;
end

% Get indices of each type of events
tBoundaries = [0; tBoundaries(:); Inf];
fields = fieldnames(eventsRaw);
for i=1:numel(tBoundaries)-1
    for j=1:numel(fields)
        subfields = fieldnames(eventsRaw.(fields{j}));
        timefield = subfields{find(strncmp('time',subfields,length('time')),1)};        
        isInSession = eventsRaw.(fields{j}).(timefield) > tBoundaries(i) & eventsRaw.(fields{j}).(timefield) < tBoundaries(i+1);
        for k=1:numel(subfields)
            eventsSplit(i).(fields{j}).(subfields{k}) = eventsRaw.(fields{j}).(subfields{k})(isInSession,:);
        end
    end
end