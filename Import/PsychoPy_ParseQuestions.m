function [questions,options,answers] = PsychoPy_ParseQuestions(text_file)

% Logs specified questions from a text file and arranges into data struct.
%
% datastruct = PsychoPy_ParseQuestions(text_file)
%
% INPUTS:
% - text_file should be the filename of the questions text file in which
%   each line starts with a code character:
%   = '?' for a question
%   = '+' for a correct answer to the preceding question
%   = '-' for an incorrect answer to the preceding question
%
% Created 2/4/15 by DJ.
    
% Set up
fid = fopen(text_file);
fseek(fid,0,'eof'); % find end of file
eof = ftell(fid);
fseek(fid,0,'bof'); % rewind to beginning


% Get the messages we're looking for
MAX_NQ = 1000; % # questions
[questions,options] = deal(cell(1,MAX_NQ));
answers = nan(1,MAX_NQ);
iQ = 0;
while ftell(fid) < eof % if we haven't reached the end of the text file
    str = fgetl(fid); % read in next line of text file
    if strncmp(str,'?',1)
        iQ = iQ + 1;
        questions{iQ} = str(2:end);
        options{iQ} = {};        
    elseif strncmp(str,'+',1)
        options{iQ} = [options{iQ},{str(2:end)}];
        answers(iQ) = length(options{iQ});
    elseif strncmp(str,'-',1)
        options{iQ} = [options{iQ},{str(2:end)}];
    end
end
% crop
questions = questions(1:iQ);
options = options(1:iQ);
answers = answers(1:iQ);

% Clean up
fclose(fid);
