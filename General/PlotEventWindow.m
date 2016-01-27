function PlotEventWindow(dataMat,times,event_times,tWindow,tBaseline,colNames)

% PlotEventWindow(datamat,times,event_times)
%
% INPUTS:
% - dataMat is TxN
%
% Created 1/21/16 by DJ.

% Declare defaults
if ~exist('times','var') || isempty(times)
    times = 1:size(dataMat,1);
end
if ~exist('event_times','var') || isempty(event_times)
    error('No event times specified!')
end
if ~exist('tWindow','var') || isempty(tWindow)
    tWindow = [-1 1];
end
if ~exist('tBaseline','var') || isempty(tBaseline)
    tBaseline = []; % no baseline subtraction
end
if ~exist('colNames','var') || isempty(colNames)    
    colNames = cell(1,size(dataMat,2));
    for i=1:size(dataMat,2)
        colNames{i} = sprintf('Data column %d',i);
    end
end

% turn tWindow into vector
if numel(tWindow)==2
    dt = median(diff(times));
    tWindow = (round((tWindow(1):dt:tWindow(2))/dt)*dt)';
end

% Get
nT = numel(tWindow);
nTypes = size(dataMat,2);
nEvents = numel(event_times);
eventMat = zeros(nT,nTypes,nEvents);
for i=1:nEvents
    tWindow_this = event_times(i)+tWindow;
    eventMat(:,:,i) = interp1(times,dataMat,tWindow_this)';
end

% subtract baseline
if ~isempty(tBaseline)
    isBaseline = (tWindow>=tBaseline(1) & tWindow<tBaseline(end));
    baselineMean = mean(eventMat(isBaseline,:,:),1);
    eventMat = eventMat-repmat(baselineMean,[nT, 1, 1]);
end

% Plot
meanEventMat = nanmean(eventMat,3);
steEventMat = nanstd(eventMat,[],3)/sqrt(nEvents);
colors = distinguishable_colors(nTypes);
for i=1:nTypes
    ErrorPatch(tWindow,meanEventMat(:,i),steEventMat(:,i),colors(i,:),colors(i,:));
%     plot(tWindow,meanEventMat(:,i),'-','color',colors(i,:),'linewidth',2);
end
legend(colNames);