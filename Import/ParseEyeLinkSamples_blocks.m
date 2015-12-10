function [events, info] = ParseEyeLinkSamples_blocks(filename,blockSize)

% Read in sample column names and values from an EyeLink samples file,
% keeping only the necessary columns to discourage memory issues.
%
% INPUTS:
% -filename is a string indicating the EyeLink samples file you want to parse.
% -blockSize is a scalar indicating how many lines should be read in per
% block. [default: 1e6]
%
% OUTPUTS:
% -events is a struct with fields samples, blinks, saccades, and fixations
% inferred from the information in the file.
% -info is a struct with raw data from the file, whose fields are
% determined by the EyeLink file's header. 
%
% Created 12/10/15 by DJ based on ParseEyeLinkSamples for larger file
% sizes.

% Declare defaults
if ~exist('blockSize','var') || isempty(blockSize)
    blockSize = 1e6;
end

%% Get fields and format spec
fprintf('Reading EyeLink samples from file %s...\n',filename)
tic
fid = fopen(filename);
% parse header
header = fgetl(fid);
fields = strsplit(header);
% produce format string
formatSpec = '';
keeperFields = {};
if any(strncmp('RIGHT',fields,length('RIGHT')))
    eyeUsed = 'RIGHT';
else
    eyeUsed = 'LEFT';
end
for i=1:numel(fields)
    switch fields{i}
        case {'TRIAL_INDEX' [eyeUsed '_IN_BLINK'] [eyeUsed '_IN_SACCADE']}            
            formatSpec = [formatSpec ' %d'];
            keeperFields = [keeperFields, fields(i)];
        case {'RECORDING_SESSION_LABEL' 'TRIAL_START_TIME' [eyeUsed '_SACCADE_INDEX']}
            formatSpec = [formatSpec ' %*d'];
        case {'TRIAL_LABEL'}
            formatSpec = [formatSpec ' %s'];
            keeperFields = [keeperFields, fields(i)];
        case {'TIMESTAMP' [eyeUsed '_GAZE_X'] [eyeUsed '_GAZE_Y'] [eyeUsed '_PUPIL_SIZE']}
            formatSpec = [formatSpec ' %f'];
            keeperFields = [keeperFields, fields(i)];
        case {'RESOLUTION_X' 'RESOLUTION_Y' [eyeUsed '_ACCELERATION_X'] [eyeUsed '_ACCELERATION_Y'] [eyeUsed '_VELOCITY_X'] [eyeUsed '_VELOCITY_Y']}
            formatSpec = [formatSpec ' %*f'];
        otherwise
            formatSpec = [formatSpec ' %*s'];
            fprintf('field %s not recognized!\n',fields{i})
    end
end
formatSpec = formatSpec(2:end);
%% Read in data in blocks
k = 0;
C = {}; % TO DO: initialize nRows using length of file
while ~feof(fid)    
	k = k+1;
    fprintf('reading block %d...\n',k)
	C(k,:) = textscan(fid,formatSpec,blockSize,'TreatAsEmpty','.','Delimiter','\t\n');
end

%% Translate cell data into info struct
info = struct();
for i=1:numel(keeperFields)
    info.(keeperFields{i}) = cat(1,C{:,i});
end
% free up memory
clear C;

%% Translate info into events struct
fprintf('Translating into samples struct...\n');
% Extract eye position if it's a numeric or character array
if isnumeric(info.([eyeUsed '_GAZE_X'])) % use as is
    eyePos = [info.([eyeUsed '_GAZE_X']), info.([eyeUsed '_GAZE_Y'])];
else % convert to double first (missing data '.' will be set to NaN)
    eyePos = [str2double(cellstr(info.([eyeUsed '_GAZE_X']))), str2double(cellstr(info.([eyeUsed '_GAZE_Y'])))];
end
% samples
events.samples.position = eyePos;
events.samples.time = info.TIMESTAMP;
if isnumeric(info.([eyeUsed '_PUPIL_SIZE'])) % use as is
    events.samples.pupilsize = info.([eyeUsed '_PUPIL_SIZE']);
else % convert to double first (missing data '.' will be set to NaN)
    events.samples.pupilsize = str2double(cellstr(info.([eyeUsed '_PUPIL_SIZE'])));
end
events.samples.eye = repmat(lower(eyeUsed(1)),size(events.samples.time));
events.samples.trial = info.TRIAL_INDEX;
% blinks
isBlinkStart = diff([0; info.([eyeUsed '_IN_BLINK'])]) > 0;
isBlinkEnd = diff([info.([eyeUsed '_IN_BLINK']); 0]) < 0;
events.blink.time_start = info.TIMESTAMP(isBlinkStart);
events.blink.time_end = info.TIMESTAMP(isBlinkEnd);
events.blink.trial = info.TRIAL_INDEX(isBlinkStart);
% saccades
isSacStart = diff([0; info.([eyeUsed '_IN_SACCADE'])]) > 0;
isSacEnd = diff([info.([eyeUsed '_IN_SACCADE']); 0]) < 0;
events.saccade.time_start = info.TIMESTAMP(isSacStart);
events.saccade.time_end = info.TIMESTAMP(isSacEnd);
events.saccade.position_start = eyePos(isSacStart,:);
events.saccade.position_end = eyePos(isSacEnd,:);
events.saccade.trial = info.TRIAL_INDEX(isSacStart);
% fixations
isInFix = ~info.([eyeUsed '_IN_SACCADE']) & ~info.([eyeUsed '_IN_BLINK']);
iFixStart = find(diff([0; isInFix]) > 0);
iFixEnd = find(diff([isInFix; 0]) < 0);
events.fixation.time_start = info.TIMESTAMP(iFixStart);
events.fixation.time_end = info.TIMESTAMP(iFixEnd);
for i=1:numel(iFixStart)
    events.fixation.position(i,:) = mean(eyePos(iFixStart(i):iFixEnd(i),:),1);
end
events.fixation.trial = info.TRIAL_INDEX(iFixStart);
% messages
if isfield(info,'SAMPLE_MESSAGE') % if this column is included
    isMsgStart = [true; any(diff(info.SAMPLE_MESSAGE,1),2)];
    events.message.time = info.TIMESTAMP(isMsgStart);
    events.message.text = cellstr(info.SAMPLE_MESSAGE(isMsgStart,:));
end
fprintf('Done! Took %.3f seconds.\n',toc)