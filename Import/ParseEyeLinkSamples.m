function [events, info] = ParseEyeLinkSamples(filename)

% Read in sample column names and values from an EyeLink samples file.
%
% INPUTS:
% -filename is a string indicating the EyeLink samples file you want to parse.
%
% OUTPUTS:
% -events is a struct with fields samples, blinks, saccades, and fixations
% inferred from the information in the file.
% -info is a struct with raw data from the file, whose fields are
% determined by the EyeLink file's header. 
%
% Created 12/1/15 by DJ. 

% Read in full file
fprintf('Reading EyeLink samples from file %s...\n',filename)
info = tdfread(filename);

% Get eye
if isfield(info,'RIGHT_GAZE_Y');
    eyeUsed = 'RIGHT';
elseif isfield(info,'LEFT_GAZE_Y');
    eyeUsed = 'LEFT';
end
% Feed results into struct
fprintf('Translating into samples struct...\n');
%% samples
events.samples.position = [info.([eyeUsed '_GAZE_X']), info.([eyeUsed '_GAZE_Y'])];
events.samples.time = info.TIMESTAMP;
events.samples.pupilsize = info.([eyeUsed '_PUPIL_SIZE']);
events.samples.eye = repmat(lower(eyeUsed(1)),size(events.samples.time));
% blinks
isBlinkStart = diff([0; info.([eyeUsed '_IN_BLINK'])]) > 0;
isBlinkEnd = diff([info.([eyeUsed '_IN_BLINK']); 0]) < 0;
events.blink.time_start = info.TIMESTAMP(isBlinkStart);
events.blink.time_end = info.TIMESTAMP(isBlinkEnd);
% saccades
isSacStart = diff([0; info.([eyeUsed '_IN_SACCADE'])]) > 0;
isSacEnd = diff([info.([eyeUsed '_IN_SACCADE']); 0]) < 0;
events.saccade.time_start = info.TIMESTAMP(isSacStart);
events.saccade.time_end = info.TIMESTAMP(isSacEnd);
events.saccade.position_start = [info.([eyeUsed '_GAZE_X'])(isSacStart), info.([eyeUsed '_GAZE_Y'])(isSacStart)];
events.saccade.position_end = [info.([eyeUsed '_GAZE_X'])(isSacEnd), info.([eyeUsed '_GAZE_Y'])(isSacEnd)];
% fixations
isInFix = ~info.([eyeUsed '_IN_SACCADE']) & ~info.([eyeUsed '_IN_BLINK']);
iFixStart = find(diff([0; isInFix]) > 0);
iFixEnd = find(diff([isInFix; 0]) < 0);
events.fixation.time_start = info.TIMESTAMP(iFixStart);
events.fixation.time_end = info.TIMESTAMP(iFixEnd);
for i=1:numel(iFixStart)
    events.fixation.position(i,:) = mean([info.([eyeUsed '_GAZE_X'])(iFixStart(i):iFixEnd(i)), info.([eyeUsed '_GAZE_Y'])(iFixStart(i):iFixEnd(i))],1);
end
% messages
isMsgStart = [true; any(diff(info.SAMPLE_MESSAGE,1),2)];
events.message.time = info.TIMESTAMP(isMsgStart);
events.message.text = cellstr(info.SAMPLE_MESSAGE(isMsgStart,:));
fprintf('Done!\n')