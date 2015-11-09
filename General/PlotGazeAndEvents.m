function PlotGazeAndEvents(events,params)

%% Plot results

% figure(571); clf;
clf;
subplot(2,1,1);
hold on;
pos = events.samples.position;
t0 = events.samples.time(1);
t = (events.samples.time-t0)/1000; % convert to seconds
plot(t,pos);
xlabel('time (sec)')
ylabel('position (pixels)')% or vel')
legend('gaze_x','gaze_y')
title(sprintf('%s position',params.filename),'interpreter','none')
% subplot(2,1,2);
% hold on;
% plot(((1:length(pos)))*dt,[vel; vel_adj; vel_total]);
% xlabel('time (sec)')
% ylabel('velocity (pix/s)')
% legend('v_x (smoothed)','v_y (smoothed)','v_x (cleaned)','v_y (cleaned)','v_{total} (v_x^2 + v_y^2)')
% title(sprintf('%s velocity',filename),'interpreter','none')
% linkaxes([subplot(211), subplot(212)],'x');
xlim([0 10]+2e2)

%% Plot blinks
% subplot(211);
for i=1:numel(events.blink.time_start)
    plot(([events.blink.time_start(i) events.blink.time_end(i)-1]-t0)/1000,[1 1]*0,'r.-','linewidth',2);
end
% subplot(212);
% for i=1:numel(iBlinkStart)
%     plot([iBlinkStart(i) iBlinkEnd(i)-1]*dt,[1 1]*0,'r.-','linewidth',2);
% end
% xlim([0 10]+2e2)

%% Plot saccades
% subplot(211);
for i=1:numel(events.saccade.time_start)
    plot(([events.saccade.time_start(i) events.saccade.time_end(i)]-t0)/1000,[1 1]*10,'b.-','linewidth',2);
end
% subplot(212);
% for i=1:numel(iSacStart)
%     plot([iSacStart(i)-.5 iSacEnd(i)-.5]*dt,[1 1]*eta_total,'b.-','linewidth',2);
% end
% xlim([0 10]+2e2)

%% Plot fixations
% subplot(211);
for i=1:numel(events.fixation.time_start)
    plot(([events.fixation.time_start(i) events.fixation.time_end(i)]-t0)/1000,[1 1]*events.fixation.position(i,1),'m.-','linewidth',2);
    plot(([events.fixation.time_start(i) events.fixation.time_end(i)]-t0)/1000,[1 1]*events.fixation.position(i,2),'y.-','linewidth',2);
end
% subplot(212);
% for i=1:numel(iSacStart)
%     plot([iSacStart(i)-.5 iSacEnd(i)-.5]*dt,[1 1]*eta_total,'b.-','linewidth',2);
% end
% xlim([0 10]+2e2)


%% Plot histograms of durations
xDur = 0:.02:1;
% figure(572); clf;
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

