function datastruct = PsychoPy_ParseEvents(text_file,types,start_code,end_code)

% Logs specified PsychoPy event types and arrange into data struct.
%
% datastruct = PsychoPy_ParseEvents(text_file,types,start_code,end_code)
%
% INPUTS:
% - text_file should be the filename of the eyelink text file.
%    To create the eyelink text file, run the .edf file created during a
%    NEDE experiment through the program Visual EDF2ASC.  For
%    event_type 'eyesample', use the EDF2ASC option 'samples only' or
%    'samples and events.'  Everything else requires 'events only' or
%    'samples and events.'
%
% EVENT TYPES AND CORRESPONDING DATASTRUCT FIELDS:
% - 'blink': times at which a blink began and ended.
% - 'button': times at which a button was pressed and number of that button
% - 'eyesample': x and y position of the eye at each sample, size of the
%    pupil at each sample
% - 'fixation': start and end time of each fixation, average x and y 
%    position of the eye during the fixation.
% - 'saccade': start and end time of the saccade, start and end position of
%    the eye during the saccade.
% - 'port': timestamp and number of each message sent.
% - 'trial': time when the trial start message was sent, trial type 
%    identifier number.
% - 'leader': time at which leader slowed down or sped up
% - 'camera': time, position & rotation of camera at each frame update
% - 'fixupdate': time, position of eye at each frame update
% - 'visible': time, object number, bounding box and fraction visible of 
%    any objects visible during a given frame
% - 'message': other text not covered by above options (NOTE: this must be
%    last, or it will 'steal' messages from the types listed above.
% - 'START': the opening of the file has a line indicating when samples
%    began being recorded. This is usually best called separately from the
%    others, with start_code = '' and end_code == 'PRESCALER'.
% - GENERIC display option: if the specified type is not any of the above, 
%    the program will search for 'MSG <x> <y> <event_type>', and will 
%    return x-y (the time when eyelink reports that it displayed the event).
%
% Created 11/12/10 by DJ.
% Updated 2/25/11 by DJ - added saccade start output
% Updated 5/31/11 by DJ - comments
% Updated 7/28/11 by DJ - added 2nd output for button option
% Updated 10/17/11 by DJ - added trialtype option for Squares experiment
% Updated 3/4/13 by DJ - added generic display option ('otherwise' in code)
% Updated 12/5/13 by DJ - added leader option
% Updated 1/23/14 by DJ - added types/start/end_code inputs, ioport-->port,
%  added fixupdate/visible/message options
% Updated 2/10/14 by DJ - updated fixupdate option, types default
% Updated 2/19/14 by DJ - fixed end trial bug
% Updated 9/10/14 by DJ - added START option.
% Updated 3/12/15 by DJ - added sequence option, fixed 'other' option
% Updated 1/19/16 by DJ - added displayset option.

if nargin<2 || isempty(types)
    types = {'block','soundset','soundstart','key','display','sequence'};%,'message'};
end
if nargin<3 || isempty(start_code)
    start_code = '~~~';
    found_start_code = true;
else
    found_start_code = false;
end
if nargin<4 || isempty(end_code)
    end_code = '~~~';
end

    
% Set up
fid = fopen(text_file);
fseek(fid,0,'eof'); % find end of file
eof = ftell(fid);
fseek(fid,0,'bof'); % rewind to beginning

% Set the parameters for our search
% word: the word we check for to find relevant events
% format: the format we use in sscanf to turn a line of text into values of interest
% values: the values returned by sscanf (we specify the # of columns here)
[words,iInfo,formats,values] = deal(cell(size(types)));
delimiters = {' ','\f','\n','\r','\t','\v','='}; % whitespace, = sign, comma
for i=1:numel(types)
    switch types{i}        
        case 'block'
            words{i} = 'Block';
            iInfo{i} = [1 5];
            formats{i} = '%f %d'; % Message format: EBLINK <eye (R/L)> <blinkstart> <blinkend>
            values{i} = cell(0,2);
        case 'soundset'
            words{i} = 'sound=';
            iInfo{i} = [1 4 6];
            formats{i} = '%f %s %c'; % Message format: <time> 	EXP 	Set <name> sound=<freq>
            values{i} = cell(0,3);
        case 'soundstart'
            words{i} = 'started';
            iInfo{i} = [1 4];
            formats{i} = '%f %s'; % Message format: <time> 	EXP 	Sound <name> started
            values{i} = cell(0,2);
        case 'key'
            words{i} = 'Keypress';
            iInfo{i} = [1 4];
            formats{i} = '%f %c'; % Message format: <time> 	DATA 	keypress: <name>
            values{i} = cell(0,2);  
        case 'display'
            words{i} = 'Display ';
            iInfo{i} = [1 4];
            formats{i} = '%f %s'; % Message format: <time> 	EXP 	Display <name>
            values{i} = cell(0,2);
        case 'displayset'
            words{i} = 'text = ';
            iInfo{i} = [1 3]; % purposefully left one out so as to catch if statement
            formats{i} = '%f %s %s'; % Message format: <time> 	EXP 	<name>: text = '<text>'
            values{i} = cell(0,3);
        case 'displaypos'
            words{i} = 'pos = ';
            iInfo{i} = [1 3 5 6]; % purposefully left one out so as to catch if statement
            formats{i} = '%f %s %f %f'; % Message format: <time> 	EXP 	<name>: pos = (x, y)
            values{i} = cell(0,4);
        case 'sequence'
            words{i} = 'Sequence';
            iInfo{i} = [1 3 5];
            formats{i} = '%f %s %d';
            values{i} = cell(0,3);
        case 'response'
            words{i} = 'Responded';
            iInfo{i} = [1 4];
            formats{i} = '%f %s';
            values{i} = cell(0,2);
        otherwise 	
            warning('FindEvents:InputType','event_type input %s not recognized!',types{i});
            words{i} = types{i};
            iInfo{i} = [1 3];
            formats{i} = '%f %s';
            values{i} = zeros(0,2);
    end
end


% Get the messages we're looking for
% each row of 'values' will be the info for one line (e.g., timestamp,
% event)
while ftell(fid) < eof % if we haven't reached the end of the text file
    str = fgetl(fid); % read in next line of text file
    % Check for start code
    if ~found_start_code 
        if isempty(findstr(str,start_code)) % if we haven't found start code yet
            continue; % skip to next line
        else
            found_start_code = true;
        end
    end        
    % Otherwise, Read in line
    for i=1:numel(types)
        if strfind(str,words{i}) % check for the code-word indicating a message was written
            if strcmp(types{i},'displaypos')
                C = strsplit(str,[delimiters,{':','(',')',','}]);
            else
                C = strsplit(str,delimiters);
            end
            stuff = C(iInfo{i});
%             stuff = sscanf(str,formats{i})';
            if size(stuff,2)==size(values{i},2)
                values{i} = [values{i}; stuff]; % add the info from this line as an additional row
            elseif strcmp(types{i},'eyesample')
                values{i} = [values{i}; NaN,NaN,NaN]; % add a blank sample so the time points still line up           
            elseif strcmp(types{i},'displayset')
                iEquals = find(str=='=',1); % text will come just after equals sign
                values{i} = [values{i}; stuff(1:2), {str(iEquals+3:end-1)}]; % exclude single quotes around text            
            else
                warning('FindEvents:IncompleteEvent','Unable to decipher the following event fully:\n %s',str); % sometimes saccades are not logged fully
            end
            break;
        end        
    end
    % Check for end code
    if ~isempty(findstr(str,end_code))
        break;
    end
end

% Clean up
fclose(fid);


for i=1:numel(types)
    % Rearrange the values into the desired output
    switch types{i}
        case 'block'
            datastruct.block.time = cellfun(@str2num,values{i}(:,1)); % first output is times at which a blink started
            datastruct.block.number = cellfun(@str2num,values{i}(:,2)); % second output is times at which a blink ended
        case 'soundset'
            datastruct.soundset.time = cellfun(@str2num,values{i}(:,1)); % first output is times at which any button was pressed
            datastruct.soundset.name = values{i}(:,2); % second output is number of the button was pressed
            datastruct.soundset.tone = values{i}(:,3); % second output is number of the button was pressed
        case 'soundstart'
            datastruct.soundstart.time = cellfun(@str2num,values{i}(:,1)); % first output is the x and y position of the eye
            datastruct.soundstart.name = values{i}(:,2); % second output is the pupil size
        case 'key'
            datastruct.key.time = cellfun(@str2num,values{i}(:,1)); % first output is timestamp of start and end of fixation
            datastruct.key.char = values{i}(:,2);%cat(1,values{i}{:,2}); % first output is timestamp of start and end of fixation
        case 'display'
            datastruct.display.time = cellfun(@str2num,values{i}(:,1)); % first output is timestamp of start and end of fixation
            datastruct.display.name = values{i}(:,2); % first output is timestamp of start and end of fixation
        case 'displayset'
            datastruct.displayset.time = cellfun(@str2num,values{i}(:,1)); % timestamp when display was set
            datastruct.displayset.name = values{i}(:,2); % name of TextStim object
            datastruct.displayset.text = values{i}(:,3); % text displayed in this text object
        case 'displaypos'
            datastruct.displaypos.time = cellfun(@str2num,values{i}(:,1)); % timestamp when display was set
            datastruct.displaypos.name = values{i}(:,2); % name of TextStim object
            datastruct.displaypos.pos = cellfun(@str2num,values{i}(:,3:4)); % position object was set to
        case 'sequence'
            datastruct.sequence.time_start = cellfun(@str2num,values{i}(strcmp('Start',values{i}(:,2)),1));
            datastruct.sequence.number = cellfun(@str2num,values{i}(strcmp('Start',values{i}(:,2)),3));
            datastruct.sequence.time_end = cellfun(@str2num,values{i}(strcmp('End',values{i}(:,2)),1));
        case 'response'
            datastruct.response.time = cellfun(@str2num,values{i}(:,1)); % first output is timestamp of response time
            datastruct.response.value = values{i}(:,2); % first output is value of response
        otherwise 
%             error('event_type input %s not recognized!',event_type);
            datastruct.(types{i}).time = cellfun(@str2num,values{i}(:,1)); % first output is display time                
            datastruct.(types{i}).name = values{i}(:,2);
    end

end