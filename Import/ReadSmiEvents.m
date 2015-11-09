function [fixation, saccade, blink, message] = ReadSmiEvents(filename)

% [fixation, saccade, blink, message] = ReadSmiEvents(filename)
%
% Created 5/6/15 by DJ.
% Updated 8/11/15 by DJ - changed last %*c to %*s to accommodate multiple dots.

fprintf('Reading SMI samples from %s...\n',filename)
% open file
fid = fopen(filename);
fseek(fid,0,'eof'); % find end of file
eof = ftell(fid);
fseek(fid,0,'bof'); % rewind to beginning

saccadeKeyword =  'Saccade';
fixationKeyword = 'Fixation';
blinkKeyword = 'Blink';
messageKeyword = 'UserEvent';
saccadeFormat = '%*s %s %*d %*d %f %f %*d %f %f %f %f %*f %*f %*f %*f %*f %*f %*f'; % stop at end loc
% Event Type	Trial	Number	Start	End	Duration	Start Loc.X	Start Loc.Y	End Loc.X	End Loc.Y	Amplitude	Peak Speed	Peak Speed At	Average Speed	Peak Accel.	Peak Decel.	Average Accel.
fixationFormat = '%*s %s %*d %*d %f %f %*d %f %f %*f %*f %*f %*f';
% Event Type	Trial	Number	Start	End	Duration	Location X	Location Y	Dispersion X	Dispersion Y	Avg. Pupil Size X	Avg Pupil Size Y
blinkFormat = '%*s %s %*d %*d %f %f %*d';
% Event Type	Trial	Number	Start	End	Duration
messageFormat = '%*s %*d %*d %f %*s %*s %s';
% Event Type	Trial	Number	Start	Description

start_code = 'UserEvent';
found_start_code = false;
[iSac, iFix, iBnk, iMsg] = deal(1);
sacMat = cell(0,7);
fixMat = cell(0,5);
bnkMat = cell(0,3);
msgMat = cell(0,2);


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
    % Otherwise, Read in line
    if strfind(str,messageKeyword)
        msgMat(iMsg,:) = textscan(str,messageFormat);
        iMsg = iMsg + 1;
    elseif strfind(str,saccadeKeyword) % check for the code-word indicating a message was written
        sacMat(iSac,:) = textscan(str,saccadeFormat);
        iSac = iSac + 1;
    elseif strfind(str,fixationKeyword)
        fixMat(iFix,:) = textscan(str,fixationFormat);
        iFix = iFix + 1;
    elseif strfind(str,blinkKeyword)
        bnkMat(iBnk,:) = textscan(str,blinkFormat);
        iBnk = iBnk + 1;
    end
end

% Convert strings to doubles ('.' --> NaN)
fprintf('converting...\n')
saccade = struct('eye',char(cat(1,sacMat{:,1})), 'time_start',double(cell2mat(sacMat(:,2)))/1e3, 'time_end',double(cell2mat(sacMat(:,3)))/1e3, 'position_start',double(cell2mat(sacMat(:,4:5))), 'position_end',double(cell2mat(sacMat(:,6:7))));
fixation = struct('eye',char(cat(1,fixMat{:,1})), 'time_start',double(cell2mat(fixMat(:,2)))/1e3, 'time_end',double(cell2mat(fixMat(:,3)))/1e3, 'position',double(cell2mat(fixMat(:,4:5))));
blink = struct('eye',char(cat(1,bnkMat{:,1})), 'time_start',double(cell2mat(bnkMat(:,2)))/1e3, 'time_end',double(cell2mat(bnkMat(:,3)))/1e3);
message = struct();
message.time = double(cell2mat(msgMat(:,1)))/1e3;
message.text = cat(1,msgMat{:,2});
fprintf('Done!\n');

