function CheckSaccadeDetection(data)

% CheckSaccadeDetection(data)
%
% Created 9/14/15 by DJ.

% Handle multi-session inputs
if numel(data)>1
    for i=1:numel(data)
        figure(570+i);
        CheckSaccadeDetection(data(i));
        drawnow;
    end
    return;
end

fprintf('Setting up...\n')
% Extract values
pos = data.events.samples.position;
t_ms = data.events.samples.time; % in ms
t_s = t_ms/1000; % convert to s
dt_s = median(diff(t_s));
filename = data.params.filename;
vel = diff(pos,[],1)/dt_s/1000;
vel_total = rssq(vel,2);
eta_total = rssq(data.thresholds.eta);

%% Plot position
fprintf('Plotting eye position samples...\n')
clf;
subplot(2,1,1);
hold on;
% plot((t_s-t_s(1)), pos);
plot((t_s-t_s(1)), pos(:,1),'b');
plot((t_s-t_s(1)), pos(:,2),'r');
xlabel('time (sec)')
ylabel('position (pixels)')
legend('x (cleaned)','y (cleaned)')
title(sprintf('%s position',filename),'interpreter','none')
grid on
% plot velocity
subplot(2,1,2);
hold on;
plot((t_s(2:end)-t_s(1)), [vel, vel_total]);
xlabel('time (sec)')
ylabel('velocity (pix/s)')
legend('v_x (cleaned)','v_y (cleaned)','v_{total} (v_x^2 + v_y^2)')
title(sprintf('%s velocity',filename),'interpreter','none')
linkaxes([subplot(211), subplot(212)],'x');
grid on;
% xlim([0 10]+200)

%% Plot blinks
fprintf('Plotting blinks...\n')
tBlinkStart = data.events.blink.time_start/1000;
tBlinkEnd = data.events.blink.time_end/1000;

subplot(211);
for i=1:numel(tBlinkStart)
    plot([tBlinkStart(i) tBlinkEnd(i)]-t_s(1),[1 1]*0,'k.-','linewidth',2);
end
% plot(t_s-t_s(1),isInBlink*0,'r.-','linewidth',2);

subplot(212);
for i=1:numel(tBlinkStart)
    plot(([tBlinkStart(i) tBlinkEnd(i)]-t_ms(1))/1000,[1 1]*0,'k.-','linewidth',2);
end
% plot(t_s-t_s(1),isInBlink*0,'r.-','linewidth',2);

% xlim([0 10]+200)

%% Plot saccades
fprintf('Plotting saccades...\n')
tSacStart = data.events.saccade.time_start/1000;
tSacEnd = data.events.saccade.time_end/1000;
sacPosStart = data.events.saccade.position_start;
sacPosEnd = data.events.saccade.position_end;

subplot(211);
% plot(t_s-t_s(1),isInSac*0,'b.-','linewidth',2);
for k=1:numel(data.events.saccade.time_start)
    plot([tSacStart(k), tSacEnd(k)]-t_s(1),...
        [sacPosStart(k,:); sacPosEnd(k,:)],'g.-');
end
subplot(212);
% plot(t_s-t_s(1),isInSac * eta_total,'b.-','linewidth',2);
for k=1:numel(data.events.saccade.time_start)
    plot([tSacStart(k), tSacEnd(k)]-t_s(1),...
        [1 1]*eta_total,'g.-');
end
% xlim([0 10]+200)

%% Plot fixations
fprintf('Plotting fixations...\n')
subplot(211);
tFixStart = data.events.fixation.time_start/1000;
tFixEnd = data.events.fixation.time_end/1000;
fixPos = data.events.fixation.position';
subplot(211);
for i=1:numel(tFixStart)
    plot([tFixStart(i) tFixEnd(i)]-t_s(1),[1 1]*fixPos(1,i),'c.-','linewidth',2);
    plot([tFixStart(i) tFixEnd(i)]-t_s(1),[1 1]*fixPos(2,i),'m.-','linewidth',2);
end
% legend('x (cleaned)','y (cleaned)','blink','saccade','xFix','yFix')
% subplot(212);
% for i=1:numel(iSacStart)
%     plot([iSacStart(i)-.5 iSacEnd(i)-.5]*dt,[1 1]*eta_total,'b.-','linewidth',2);
% end
xlim([0 10]+200)
% annotate
MakeLegend({'b','r','k.-','g.-','c.-','m.-'},{'x (cleaned)','y (cleaned)','blink','saccade','xFix','yFix'});

%% Plot histograms of durations
fprintf('Plotting histograms...\n')
xDur = 0:dt_s:1;
figure(get(gcf,'Number')+100); clf;
subplot(131);
hist((tBlinkEnd-tBlinkStart),xDur);
xlabel('blink duration (s)');
ylabel('# blinks');
title(sprintf('%s blinks',filename),'interpreter','none')
xlim([xDur(1) xDur(end)]);
subplot(132);
hist((tSacEnd-tSacStart),xDur);
xlabel('saccade duration (s)');
ylabel('# saccades');
title(sprintf('%s saccades',filename),'interpreter','none')
xlim([xDur(1) xDur(end)]);
subplot(133);
hist((tFixEnd-tFixStart),xDur);
xlabel('fixation duration (s)');
ylabel('# fixations');
title(sprintf('%s fixations',filename),'interpreter','none')
xlim([xDur(1) xDur(end)]);
fprintf('Done!\n')
