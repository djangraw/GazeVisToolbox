function data = ImportRsqBehavior(filename,doPlot)

% data = ImportRsqBehavior(filename,doPlot)
%
% INPUTS:
% - filename is a string indicating the name of the psychopy log file to
% import.
% - doPlot is a boolean indicating whether you'd like to plot the responses
% and response times (in chronological order).
%
% OUTPUTS:
% - data is a struct with fields 'params', 'events', and 'questions'.
%
% Created 9/9/15 by DJ.

% declare defaults
if ~exist('doPlot','var') || isempty(doPlot)
    doPlot = false;
end

% load parameters
params = PsychoPy_ParseParams(filename,'---START PARAMETERS---','---END PARAMETERS---');
params.questionOrder = str2double(params.questionOrder)+1;
% load questions
[questions,~,~,comments] = PsychoPy_ParseQuestions(params.questionFile);
questions_sorted = questions(params.questionOrder);
comments_sorted = comments(params.questionOrder);
% load events
events = PsychoPy_ParseEvents(filename,{'key','display','response'});
events.response.value = str2double(events.response.value); % convert q #'s from strings to doubles
tQ = events.display.time(strncmp(events.display.name,'Question',length('Question')));
tA = events.response.time;
events.response.RT = tA-tQ;

% declare output struct
data.params = params;
data.events = events;
data.questions.text = questions_sorted;
data.questions.categories = comments_sorted;

% plot results (if desired)
if doPlot
    % set up
    figure(99); clf;
    set(gcf, 'Position', get(0,'Screensize')); % maximize figure
    % plot the responses
    PlotRawRsqBehavior(data);
end