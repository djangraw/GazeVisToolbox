function data = ImportSmiData_All(logFilenames,smiFilenames,eventFilenames,thresholds)

% data = ImportSmiData_All(logFilenames,smiFilenames,eventFilenames,thresholds)
%
% INPUTS:
% -logFilenames is a cell array of strings (of length N) indicating the 
% PsychoPy log files you'd like to import with ImportSmiData_All.
% -smiFilenames is a cell array of strings (of length M<=N) indicating the 
% SMI log files you'd like to import with ImportSmiData_All. M can be <N if
% >1 session was recorded in an SMI file.
% -thresholds is a struct indicating various smoothing and event detection 
% thresholds. See ImportSmiData_Engbert.m for details.
%
% OUTPUTS:
% -data is an N-element array of structs containing information about the 
% N experimental sessions.
%
% Created 9/14/15 by DJ.
% Updated 9/22/15 by DJ - removed vertical flip
% Updated 10/30/15 by DJ - addded eventFilenames input

if ~exist('thresholds','var')
    thresholds = [];
end

% Import PsychoPy log files
fprintf('===Importing %d PsychoPy log files...\n',numel(logFilenames))
for i=1:numel(logFilenames)
    data(i) = ImportDistractionData_PsychoPy(logFilenames{i});
end
% Import SMI text files
fprintf('===Importing %d SMI log files...\n',numel(smiFilenames))
for i=1:numel(smiFilenames)
    [eventsRaw(i), thresholds_out(i)] = ImportSmiData_Engbert(smiFilenames{i},eventFilenames{i},data(1).params.screenSize,thresholds);
end

% Split SMI files if need be
fprintf('===Splitting SMI events into sessions...\n')
eventsSplit = cell(1,numel(eventsRaw));
[smiFilenamesSplit, thresholdsSplit] = deal(cell(1,numel(eventsRaw)));
for i=1:numel(eventsRaw)
    tSamples = eventsRaw(i).samples.time;
    iSessionBoundary = find(diff(tSamples)>10000); % find boundaries
    % split!
    if ~isempty(iSessionBoundary)
        eventsSplit{i} = SplitSmiEventsStruct(eventsRaw(i),tSamples(iSessionBoundary)+5);        
        smiFilenamesSplit{i} = repmat(smiFilenames(i),size(eventsSplit{i}));
        thresholdsSplit{i} = repmat(thresholds_out(i),size(eventsSplit{i}));
    else
        eventsSplit{i} = eventsRaw(i);
        smiFilenamesSplit{i} = smiFilenames(i);
        thresholdsSplit{i} = thresholds_out(i);
    end
end
events = cat(1,eventsSplit{:});
eventsFilename = cat(1,smiFilenamesSplit{:});
thresholds_new = cat(1,thresholdsSplit{:});

% Check for match
if numel(data) ~= numel(events)
    error('number of SMI sessions and number of PsychoPy sessions don''t match!');
end

% Combine data and events
fprintf('===Combining PsychoPy and SMI data structs...\n')
smiFields = fieldnames(events);
psyFields = fieldnames(data(1).events);
for i=1:numel(data);
    % copy over events fields
    for j=1:numel(smiFields)
        data(i).events.(smiFields{j}) = events(i).(smiFields{j});
    end
    % copy over SMI filename and import parameters
    data(i).params.smiFilename = eventsFilename{i};
    data(i).thresholds = thresholds_new(i);
end

% check sync
fprintf('===Checking sync event agreement...\n')
syncEvents = {'Fixation','Page'};
delay = CheckSync_SmiData(data,syncEvents);

% convert timing to unified times
fprintf('===Unifying timing to SMI times...\n')
data = UnifyTiming_PsyToSmi(data,syncEvents,psyFields);

% flip positions vertically
% fprintf('===Flipping SMI positions vertically (upper left = (0,0))...\n')
% data = FlipPositions_Smi(data,'vertical');

fprintf('===Done!\n');