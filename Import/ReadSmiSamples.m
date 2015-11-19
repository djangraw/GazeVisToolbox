function [samples, messages] = ReadSmiSamples(filename,sampleFormat,messageFormat)

% [samplesL, pupilL, samplesR, pupilR, tStart] = ReadSmiSamples(filename)
%
% Created 5/6/15 by DJ.
% Updated 8/11/15 by DJ - changed last %*c to %*s to accommodate multiple dots.
% Updated 11/3/15 by DJ - allow custom sampleFormat inputs

if ~exist('sampleFormat','var') || isempty(sampleFormat)
    sampleFormat = '%f %*s %d %f %f %f %f %f %f %f %f %*f %f %*f';
%   samples = struct('tSample',sampleMat(:,1), 'trial',sampleMat(:,2), 'sampleRaw',sampleMat(:,3:4), 'PD',sampleMat(:,5:6), 'CR',sampleMat(:,7:8), 'POR',sampleMat(:,9:10), 'pupilConf',sampleMat(:,11));

end
if ~exist('messageFormat','var') || isempty(messageFormat)
    messageFormat = '%f %*s %d %*s %*s %s';
end

fprintf('Reading SMI samples from %s...\n',filename)
% open file
fid = fopen(filename);
fseek(fid,0,'eof'); % find end of file
eof = ftell(fid);
fseek(fid,0,'bof'); % rewind to beginning

sampleKeyword =  'SMP';
messageKeyword = 'MSG';

% EXAMPLES:
% normal: 2389904	  777.2	  597.3	 1801.0	  813.4	  575.7	 1313.0	  120.0	.
% blink: 2391224	   .	   .	    0.0	   .	   .	    0.0	  120.0	.

start_code = 'SMP';
found_start_code = false;
iSample = 1;
iMessage = 1;
sampleMat = [];
% messageMat = [];
messageMat = cell(0,3);

while ftell(fid) < eof % if we haven't reached the end of the text file
    str = fgetl(fid); % read in next line of text file    
    % Check for start code
    if ~found_start_code 
        if isempty(strfind(str,start_code)) % if we haven't found start code yet
            continue; % skip to next line
        else
            found_start_code = true;
        end
    end        
    % skip commented lines
    if strncmp(str,'##',2), continue; end
    % Otherwise, Read in line
    if strfind(str,sampleKeyword) % check for the code-word indicating a message was written
        sampleMat(iSample,:) =  sscanf(str,sampleFormat);
        iSample = iSample+1;
    elseif strfind(str,messageKeyword)
        messageMat(iMessage,:) = textscan(str,messageFormat);
        iMessage = iMessage + 1;
    end
end

% Convert strings to doubles ('.' --> NaN)
fprintf('converting...\n')
%% KLUGED VARIATIONS ON INPUT
if size(sampleMat,2)>10 % default version
    samples = struct('tSample',sampleMat(:,1), 'trial',sampleMat(:,2), 'sampleRaw',sampleMat(:,3:4), 'PD',sampleMat(:,5:6), 'CR',sampleMat(:,7:8), 'POR',sampleMat(:,9:10), 'pupilConf',sampleMat(:,11));
else % Valentinos version
    samples = struct('tSample',sampleMat(:,1), 'trial',sampleMat(:,2),'POR',sampleMat(:,3:4));
end
messages = struct('tMessage',[],'text',[],'trial',[]);
if ~isempty(messageMat)
    if size(messageMat,2)==2 % old default version
        messages.tMessage = cat(1,messageMat{:,1});
        messages.text = cat(1,messageMat{:,2});
    else % New/Valentinos version
        messages.tMessage = cat(1,messageMat{:,1});
        messages.trial = cat(1,messageMat{:,2});
        messages.text = cat(1,messageMat{:,3});
    end
end
fprintf('Done!\n');

