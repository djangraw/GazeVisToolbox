function PlotRawRsqBehavior(data,sortByCategory)

% Plot the response and RT for each question in the order in which they
% were presented.
%
% PlotRawRsqBehavior(data,sortByCategory)
%
% INPUTS:
% -data is a struct with subfields params, events, and questions, as
% imported by ImportRsqBehavior.
% -sortByCategory is a binary value indicating whether you'd like to keep
% questions in the same category together rather than going
% chronologically. [default = false] 
%
% Created 12/1/15 by DJ.

% declare defaults
if ~exist('sortByCategory','var') || isempty(sortByCategory)
    sortByCategory = false;
end

% set up
nQ = numel(data.questions.text);
categories = data.questions.categories;
questions = data.questions.text;
resp = data.events.response.value;
RT = data.events.response.RT;
filename = data.params.filename;

% sort
if sortByCategory
    [categories,order] = sort(data.questions.categories);
    questions = questions(order);
    resp = resp(order);
    RT = RT(order);
end

% plot the responses
clf;
subplot(1,2,1);
plot(resp,1:nQ,'.-');

% superimpose the category colors
hold on
cats = unique(categories);
colors = distinguishable_colors(numel(cats));
for i=1:numel(cats)
    isInCat = strcmp(categories,cats{i});
    plot(resp(isInCat),find(isInCat),'o','color',colors(i,:));
end

% annotate plot
xlabel(sprintf('Response\n<-----Agree-------Disagree--->'));
ylabel('question');
set(gca,'xtick',1:5,'ytick',1:nQ,'yticklabel',questions,'ydir','reverse');
ylim([0 nQ+1])
grid on
title([filename ' responses'],'interpreter','none');
legend([{'All'},cats]);

% plot the response times
subplot(1,2,2);    
plot(RT,1:nQ,'.-');

% superimpose the category colors
hold on
for i=1:numel(cats)
    isInCat = strcmp(categories,cats{i});
    plot(RT(isInCat),find(isInCat),'o','color',colors(i,:));
end

% annotate plot
xlabel('RT (s)');
ylabel('question');
set(gca,'ytick',1:nQ,'yticklabel',questions,'ydir','reverse');
ylim([0 nQ+1])
grid on
title([filename ' response times'],'interpreter','none');
legend([{'All'},cats]);