function [params, sampleCols] = ReadSmiSampleHeader(filename)

% Read in parameters and sample column names from SMI samples file header
%
% INPUTS:
% -filename is a string indicating the SMI samples file you want to import.
%
% OUTPUTS:
% -params is a struct including fields and subfelds indicated by the SMI
% file's header.
% -sampleCols is a cell array of strings indicating the name of each
% column in the sample lines.
%
% Created 11/19/15 by DJ. 

fprintf('Reading SMI sample header from %s...\n',filename)
% open file
fid = fopen(filename);
fseek(fid,0,'eof'); % find end of file
eof = ftell(fid);
fseek(fid,0,'bof'); % rewind to beginning

% Set up
params = struct;
subfield = '';
% Main Loop
while ftell(fid) < eof % if we haven't reached the end of the text file
    str = fgetl(fid); % read in next line of text file    
    % Add results
    if strncmp(str,'## [',4) % a header
        subfield = str(isstrprop(str,'alphanum'));        
    elseif strncmp(str,'##',2) % a field-value pair
        iColon = find(str==':',1,'first');
        % separate out field and value
        if ~isempty(iColon)
            field = str(4:iColon-1); % exclude '## '
            field = field(isstrprop(field,'alphanum')); % restrict to alpha-numerics, which can be in the field name
            value = str(iColon+2:end); % exclude tab char that follows ':'
            % Add to params struct
            if isempty(subfield)
                params.(field) = value;
            else
                params.(subfield).(field) = value;
            end
        end        
    else
        % Get column names (tab-delimited)
        sampleCols = strsplit(str,'\t');        
        % header is over - end the loop.
        break
    end
end
fprintf('Done!\n')