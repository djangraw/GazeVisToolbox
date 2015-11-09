function params = PsychoPy_ParseParams(text_file,start_code,end_code)

% Reads in parameter values from a NEDE data file.
%
% params = NEDE_ParseParams(text_file,start_code, end_code)
%
% This function reads an EyeLink text file from a NEDE task and
% parses information about the objects created in that task into useful
% structs for later analysis.
%
% INPUTS:
% - text_file is the filename of the Unity Log (something like
% 'NEDE_1pt0-0-0.txt').
%
% OUTPUTS:
% - params will be a structure of parameters.
%
% Created 1/23/14 by DJ.
% Updated 9/22/15 by DJ - debugged to allow tuples (by making parentheses
%  delimiters rather than ignoring them entirely)

if nargin<2 || isempty(start_code)
    start_code = 'START PARAMETERS';
end
if nargin<2 || isempty(end_code)
    end_code = 'END PARAMETERS';
end

% Setup
fid = fopen(text_file);
fseek(fid,0,'eof'); % find end of file
eof = ftell(fid);
fseek(fid,0,'bof'); % rewind to beginning


str = '';
% Find Trial markers and read in object info.
while ftell(fid) < eof && isempty(findstr(str,start_code)) % if we haven't found the session params or reached the end of the text file    
    str = fgetl(fid); % read in next line of text file
end
while ftell(fid) < eof && isempty(findstr(str,end_code)) % check for the code-word indicating loading started
    str = fgetl(fid); % read in next line of text file
    % Categories are a special case because they place multiple params on the same line    
    if findstr(str,'notes:')         
        %notes: ['c', 'f', 'a']
        lineinfo = textscan(str,'%*f INFO notes: %c %c %c','Delimiter','[]'',(): ','MultipleDelimsAsOne',true); 
        noteinfo = lineinfo;
        if ~isfield(params,'notes')
            params.notes = noteinfo;
        else
            params.notes = [params.notes, noteinfo];
        end
        
    % For all other parameters, just transfer the value to a matlab struct
    elseif findstr(str,':') % if it's a parameter              
%         lineinfo = textscan(str,'%*f INFO %s %s','Delimiter',',(): ','MultipleDelimsAsOne',true); 
        lineinfo = textscan(str,'%*f INFO %s %s','Delimiter',',: ','MultipleDelimsAsOne',true); 
        fieldname = lineinfo{1}{1};
        if isempty(lineinfo{2})
            fieldvalue = '';
        else
            fieldvalue = lineinfo{2}{1};  
        end
        % transfer numbers/booleans without quotes
        if ~isempty(fieldvalue) && ~isnan(str2double(fieldvalue)) && imag(str2double(fieldvalue))==0 || ismember(fieldvalue,{'True','False'});
            eval(sprintf('params.%s = %s;',fieldname,lower(fieldvalue))); % use 'lower' to make valid true/false input
        elseif ~isempty(strfind(str,',')) % transfer strings with quotes
            iFieldStart = strfind(str,fieldname) + length(fieldname) + 2;
%             info = strsplit(str(iFieldStart:end),{'[',']',',','''',' '},'CollapseDelimiters',1);
            info = strsplit(str(iFieldStart:end),{'(',')','[',']',',','''',' '},'CollapseDelimiters',1);
            params.(fieldname) = info(2:end-1);
        else
            eval(sprintf('params.%s = ''%s'';',fieldname,fieldvalue));
        end
    end        
end