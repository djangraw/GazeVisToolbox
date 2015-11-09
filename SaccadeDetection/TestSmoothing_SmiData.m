function TestSmoothing_SmiData(logFilenames,smiFilenames,winLengths)
% Plot saccade and fixation detection results at various smoothing levels.
%
% TestSmoothing_SmiData(logFilenames,smiFilenames,winLengths)
%
% INPUTS:
% -logFilenames is a cell array of strings indicating the PsychoPy log
% files you'd like to import with ImportSmiData_All.
% -smiFilenames is a cell array of strings indicating the SMI log files
% you'd like to import with ImportSmiData_All.
% -winLengths is a vector of values you want to investigate for the width
% of the gaussian used to smooth the raw eye position data.
% -iSession is a scalar indicating the index of the session to be plotted.
% -tWin is a 2-element vector indicating the desired time limits of the
% plot.
%
% Created 9/16/15 by DJ.

% Declare defaults
if ~exist('winLengths','var') || isempty(winLengths)
    winLengths = 0:0.25:1;
end
if ~exist('iSession','var') || isempty(iSession)
    iSession = 1;
end
if ~exist('tWin','var') || isempty(tWin)
    tWin = [1 10] + 100;
end

%% Get data
datatest = cell(size(winLengths));
for j=1:numel(winLengths)
    thresholds = struct('winLength',winLengths(j),'minBlinkDur',0,'minIbi',50,'minSacDur',0,'minIsi',50,'velThresh',3);
    datatest{j} = ImportSmiData_All(logFilenames, smiFilenames, thresholds);
end

%% Plot
figure(482); clf;
for j=1:numel(winLengths)
    data = datatest{j};
    samples = data(iSession).events.samples.position;
    t = data(iSession).events.samples.time;
    
    subplot(numel(winLengths),1,j); cla; hold on;
    plot((t-t(1))/1000,samples);
    tSacStart = data(iSession).events.saccade.time_start;
    tSacEnd = data(iSession).events.saccade.time_end;
    for k=1:numel(data(iSession).events.saccade.time_start)
        plot(([data(iSession).events.saccade.time_start(k), data(iSession).events.saccade.time_end(k)]-t(1))/1000,...
            [data(iSession).events.saccade.position_start(k,:);data(iSession).events.saccade.position_end(k,:)],'g.-');
    end
    for k=1:numel(data(iSession).events.fixation.time_start)
        plot(([data(iSession).events.fixation.time_start(k), data(iSession).events.fixation.time_end(k)]-t(1))/1000,...
            [data(iSession).events.fixation.position(k,:);data(iSession).events.fixation.position(k,:)],'m.-');
    end
    % annotate plot
    xlabel('time (s)')
    ylabel(sprintf('winLength = %.2f',winLengths(j)))
    if j==1
        title(data(iSession).params.filename,'interpreter','none');
    end
    xlim(tWin);
end
linkaxes(GetSubplots(gcf));

%% Make Eye Movie
% i = 2;
% j = 4;
% data = datatest{j};
% samples = data(i).events.samples.position;
% pupilsize = rssq(data(i).events.samples.PD,2);
% % record_time = data(i).events.samples.time(1);
% record_time = data(i).events.samples.time(1);
% 
% eyeToUse = [];
% fs = 1000/nanmedian(diff(data(i).events.samples.time));
% screenSize = data(i).params.screenSize;
% 
% MakeEyeMovie_Reading(samples,pupilsize,record_time,data(i).events,data(i).pageinfo,eyeToUse,fs,screenSize)
