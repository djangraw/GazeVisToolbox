function PlotGazeAndEvents(events)

% Plot the positions and events from an EyeLink or SMI events struct.
%
% PlotGazeAndEvents(events,params)
%
% INPUTS:
% -events is a struct with samples, blink, fixation, and saccade subfields.
%
% NOTE: assumes all times are in ms.
%
% Created 11/2/15 by DJ.
% Updated 12/1/15 by DJ - comments and cleanup.

%% Plot eye position
clf;
subplot(2,1,1);
hold on;
pos = events.samples.position;
t0 = events.samples.time(1);
t = (events.samples.time-t0)/1000; % offset so first sample is at t=0, and convert from ms to seconds
h = plot(t,pos);
% annotate plot
xlabel('time (s)')
ylabel('position (pixels)')% or vel')
plotColors = get(h,'Color');
title('eye position','interpreter','none')
% xlim([0 10]+2e2)
% make legend for all the event types
MakeLegend([plotColors; {'r';'b';'m';'y'}],{'gaze_x','gaze_y','blink','saccade','fixation_x','fixation_y'},[1 1 2 2 2 2]);

%% Plot blinks
for i=1:numel(events.blink.time_start)
    plot(([events.blink.time_start(i) events.blink.time_end(i)-1]-t0)/1000,[1 1]*0,'r.-','linewidth',2);
end

%% Plot saccades
for i=1:numel(events.saccade.time_start)
    plot(([events.saccade.time_start(i) events.saccade.time_end(i)]-t0)/1000,[1 1]*10,'b.-','linewidth',2);
end

%% Plot fixations
for i=1:numel(events.fixation.time_start)
    plot(([events.fixation.time_start(i) events.fixation.time_end(i)]-t0)/1000,[1 1]*events.fixation.position(i,1),'m.-','linewidth',2);
    plot(([events.fixation.time_start(i) events.fixation.time_end(i)]-t0)/1000,[1 1]*events.fixation.position(i,2),'y.-','linewidth',2);
end


%% Plot histograms of durations
xDur = 0:.02:1;
subplot(234);
hist((events.blink.time_end-events.blink.time_start)/1000,xDur);
xlabel('blink duration (s)');
ylabel('# blinks');
title(sprintf('Blinks'),'interpreter','none')
xlim([xDur(1) xDur(end)]);
subplot(235);
hist((events.fixation.time_end-events.fixation.time_start)/1000,xDur);
xlabel('saccade duration (s)');
ylabel('# saccades');
title(sprintf('Saccades'),'interpreter','none')
xlim([xDur(1) xDur(end)]);
subplot(236);
hist((events.saccade.time_end-events.saccade.time_start)/1000,xDur);
xlabel('fixation duration (s)');
ylabel('# fixations');
title(sprintf('Fixations'),'interpreter','none')
xlim([xDur(1) xDur(end)]);

