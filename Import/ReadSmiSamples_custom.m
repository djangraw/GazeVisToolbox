function [samples, messages, params] = ReadSmiSamples_custom(filename,sampleCols,messageCols)

% [samples, messages, params] = ReadSmiSamples_custom(filename,sampleCols,messageCols)
%
% INPUTS:
% -filename is a string indicating the name of the SMI samples file.
% -sampleCols is a cell array of the parameters in the rows for samples.
% [default: use ReadSmiSampleHeader to read in these values]
% -messageCols is a cell array of the parameters in the rows for messages.
% [default: {'Time','Type','Trial','Text'}]
%
% OUTPUTS:
% -samples is a struct with fields for all of the parameters listed in
% sampleCols, and each will contain n elements for the n events of that
% type that were recorded. 
% -messages is the same as samples, but for message events.
% -params is a struct of acquisition parameters created from the header
% using ReadSmiSampleHeader (only if input sampleCols is not provided).
%
% Created 5/6/15 by DJ.
% Updated 8/11/15 by DJ - changed last %*c to %*s to accommodate multiple dots.
% Updated 11/3/15 by DJ - allow custom sampleFormat inputs
% Updated 11/19/15 by DJ - changed to 'custom' version where file header
% text determines event struct fields.

% Handle defaults
if ~exist('sampleCols','var') || isempty(sampleCols)
    [params,sampleCols] = ReadSmiSampleHeader(filename);
else
    params = struct; % create empty struct for output
end
if ~exist('messageCols','var') || isempty(messageCols)
    messageCols = {'Time','Type','Trial','Text'};
end

% Construct sample format string from known column names
sampleFormat = '';
for i=1:numel(sampleCols)
    % Append new format chars to string
    switch sampleCols{i}
        case {'Type', 'Aux1', 'Image'}
            sampleFormat = [sampleFormat ' %s'];
        case {'N/A'}
            sampleFormat = [sampleFormat ' %*s'];
        case {'Trial', 'TrialID', 'TrialType'}               
            sampleFormat = [sampleFormat ' %d'];
        otherwise
            sampleFormat = [sampleFormat ' %f'];
    end
    % remove initial space
    if i==1, sampleFormat(1) = ''; end
end
% N/A's will not be included, so remove them
sampleCols(strcmp('N/A',sampleCols)) = [];

% Construct message format string from known column names
messageFormat = '';
for i=1:numel(messageCols)    
    switch messageCols{i}
        % Append new format chars to string
        case {'Type','Text','Image'}
            messageFormat = [messageFormat ' %s'];
        case {'N/A'}
            messageFormat = [messageFormat ' %*s'];
        case {'Trial', 'TrialID', 'TrialType'}
            messageFormat = [messageFormat ' %d'];
        otherwise
            messageFormat = [messageFormat ' %f'];
    end
    % remove initial space
    if i==1, messageFormat(1) = ''; end
end
% N/A's will not be included, so remove them
messageCols(strcmp('N/A',messageCols)) = [];
        

% Load file and fine beginning/end
fprintf('Reading SMI samples from %s...\n',filename)
% open file
fid = fopen(filename);
fseek(fid,0,'eof'); % find end of file
eof = ftell(fid);
fseek(fid,0,'bof'); % rewind to beginning

% Set up for main loop
sampleKeyword =  'SMP';
messageKeyword = 'MSG';
start_codes = {'SMP', 'MSG'};
found_start_code = false;
iSample = 1;
iMessage = 1;
sampleMat = cell(0,numel(sampleCols));
messageMat = cell(0,numel(messageCols));

% Main loop: read in data
while ftell(fid) < eof % if we haven't reached the end of the text file
    str = fgetl(fid); % read in next line of text file    
    % skip over comments lines
    if strncmp(str,'##',2)
        continue; 
    end
    % Check for start code
    if ~found_start_code 
        for i=1:numel(start_codes)
            if ~isempty(strfind(str,start_codes{i})) % if we haven't found start code yet
                found_start_code = true;
            end
        end
    end
    % Read in line
    if found_start_code % Restart if statement to account for found_start_code change
        if strfind(str,sampleKeyword) % check for the code-word indicating a message was written
            sampleMat(iSample,:) =  textscan(str,sampleFormat,'delimiter','\t');
            iSample = iSample+1;
        elseif strfind(str,messageKeyword)
            messageMat(iMessage,:) = textscan(str,messageFormat,'delimiter','\t');
            iMessage = iMessage + 1;
        end
    end
end

% Convert results into structs
fprintf('converting to struct...\n')
for i=1:numel(sampleCols)
    field = sampleCols{i}(isstrprop(sampleCols{i},'alphanum'));
    samples.(field) = cat(1,sampleMat{:,i});
end
for i=1:numel(messageCols)
    field = messageCols{i}(isstrprop(messageCols{i},'alphanum'));
    messages.(field) = cat(1,messageMat{:,i});
    % Messages: get rid of the standard '# Message: ' text
    if strcmp(field,'Text')
        for j=1:numel(messages.(field))
            messages.(field){j}(1:length('# Message: ')) = [];
        end
    end        
end
fprintf('Done!\n');

