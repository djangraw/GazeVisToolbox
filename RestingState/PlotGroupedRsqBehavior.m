function PlotGroupedRsqBehavior(data)

% Plot the response and RT for each question in the order in which they
% were presented.
%
% PlotGroupedRsqBehavior(data)
%
% INPUTS:
% -data is a struct with subfields params, events, and questions, as
% imported by ImportRsqBehavior.
%
% Created 12/1/15 by DJ.

% set up
nQ = numel(data.questions.text);
RT = data.events.response.RT;
questions_sorted = data.questions.text;
filename = data.params.filename;

% get the response histograms
cats = unique(data.questions.categories);
xResp = 1:5;
xRT = linspace(0,max(RT),10);
yResp = nan(numel(cats),length(xResp));
yRT = nan(numel(cats),length(xRT));
[meanResp,meanRT,stdResp,stdRT] = deal(nan(1,numel(cats)));
for i=1:numel(cats)
    isInCat = strcmp(data.questions.categories,cats{i});    
    yResp(i,:) = hist(data.events.response.value(isInCat),xResp)/sum(isInCat)*100;
    yRT(i,:) = hist(RT(isInCat),xRT)/sum(isInCat)*100;
    meanResp(i) = mean(data.events.response.value(isInCat));
    meanRT(i) = mean(RT(isInCat));
    stdResp(i) = std(data.events.response.value(isInCat));
    stdRT(i) = std(RT(isInCat));    
end

% Plot the response histos
colors = distinguishable_colors(numel(cats));
clf;
subplot(2,2,1); hold on;
% plot as lines
for i=1:numel(cats)
    plot(xResp,yResp(i,:),'.-','color',colors(i,:));
end
% % plot as bars
% h = bar(xResp,yResp');
% % correct colors
% for i=1:numel(cats)
%     set(h(i),'facecolor',colors(i,:))
% end

% annotate plot
xlabel(sprintf('Response\n<-----Agree-------Disagree--->'));
ylabel('frequency of occurrence (%)');
set(gca,'xtick',1:5);
grid on
title([filename ' responses'],'interpreter','none');
legend(cats);


% plot the response time histos
subplot(2,2,2); hold on;
% plot as lines
for i=1:numel(cats)
    plot(xRT,yRT(i,:),'.-','color',colors(i,:));
end
% % plot as bars
% h = bar(xRT,yRT');
% % correct colors
% for i=1:numel(cats)
%     set(h(i),'facecolor',colors(i,:))
% end

% annotate plot
xlabel('RT (s)');
ylabel('frequency of occurrence (%)');
grid on
title([filename ' response times'],'interpreter','none');
legend(cats);

%% Make Mean/Std plots

% Plot the response mean/std as bars
subplot(2,2,3); hold on;
% make bars and correct colors 
for i=1:numel(cats)
    h(i) = bar(i,6-meanResp(i));
    set(h(i),'facecolor',colors(i,:))    
end
% add std errorbars
errorbar(6-meanResp,stdResp,'k.');

% annotate plot
ylabel(sprintf('Response\n<---Disagree-------Agree----->'));
xlabel('Question Group (see legend)')
set(gca,'ytick',1:5,'yticklabel',{'5','4','3','2','1'});
ylim([1 5])
grid on
title([filename ' responses'],'interpreter','none');
legend(cats);


% plot the response time histos as lines
subplot(2,2,4); hold on;
% make bars and correct colors 
for i=1:numel(cats)
    h(i) = bar(i,meanRT(i));
    set(h(i),'facecolor',colors(i,:));    
end
% add std errorbars
errorbar(meanRT,stdRT,'k.');


% annotate plot
ylabel('RT (s)');
xlabel('Question Group (see legend)')
grid on
title([filename ' response times'],'interpreter','none');
legend(cats);