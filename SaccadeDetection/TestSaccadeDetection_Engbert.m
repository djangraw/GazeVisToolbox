% TestSaccadeDetection_Engbert.m
%
% Created 9/10/15 by DJ.
% Updated 11/20/15 by DJ - switched to ReadSmiSamples_custom

% Import samples and messages
filename = 'DistractionTask_S1-Samples.txt';
[samples0,messages,paramsRaw] = ReadSmiSamples_custom(filename);
pos_raw = [samples0.RPORXpx, samples0.RPORYpx]';
dt = median(diff(samples0.Time))/1e3; % convert from us to ms

% make fake eye pos
% x_raw  = [1:10,10*ones(1,10), 10:-1:1];
% y_raw = x_raw/2;
% pos_raw = [x_raw; y_raw];
% dt = 1/60;

%% detect outliers
isOutlier = any(pos_raw <= 0,1) | pos_raw(1,:) > screenSize(1) | pos_raw(2,:) > screenSize(2);
pos_raw(:,isOutlier) = 0;

%% Get smoothed position
winLength = 0;
[pos,vel] = SmoothEyePos_Engbert(pos_raw,winLength,dt);

%% detect blinks
minBlinkDur = 0;%0.033;
minIbi = 0.050;
[iBlinkStart,iBlinkEnd,pos_adj] = GetBlinks_Engbert(pos,dt,minBlinkDur,minIbi);

vel_adj = vel;
for i=1:numel(iBlinkStart)
    vel_adj(:,iBlinkStart(i):iBlinkEnd(i)-1) = NaN;
end
vel_total = rssq(vel_adj,1);

%% detect saccades
minDur = 0;%0.033;
minIsi = 0.050;
velThresh = 3;
[iSacStart,iSacEnd,eta] = GetSaccades_Engbert(vel_adj,dt,minDur,minIsi,velThresh);
eta_total = rssq(eta);

%% detect fixations
[iFixStart,iFixEnd,fixPos] = GetFixations_Engbert(iSacStart,iSacEnd,iBlinkStart,iBlinkEnd,pos_adj);

%% Plot results

figure(571); clf;
subplot(2,1,1);
hold on;
plot((1:length(pos_raw))*dt,[pos_raw; pos; pos_adj]);
xlabel('time (sec)')
ylabel('position (pixels)')% or vel')
legend('x (raw)','y (raw)','x (smoothed)','y (smoothed)','x (cleaned)','y (cleaned)')
title(sprintf('%s position',filename),'interpreter','none')
subplot(2,1,2);
hold on;
plot(((1:length(pos_raw)))*dt,[vel; vel_adj; vel_total]);
xlabel('time (sec)')
ylabel('velocity (pix/s)')
legend('v_x (smoothed)','v_y (smoothed)','v_x (cleaned)','v_y (cleaned)','v_{total} (v_x^2 + v_y^2)')
title(sprintf('%s velocity',filename),'interpreter','none')
linkaxes([subplot(211), subplot(212)],'x');
xlim([0 10]+2e2)

%% Plot blinks
subplot(211);
for i=1:numel(iBlinkStart)
    plot([iBlinkStart(i) iBlinkEnd(i)-1]*dt,[1 1]*0,'r.-','linewidth',2);
end
subplot(212);
for i=1:numel(iBlinkStart)
    plot([iBlinkStart(i) iBlinkEnd(i)-1]*dt,[1 1]*0,'r.-','linewidth',2);
end
xlim([0 10]+2e2)

%% Plot saccades
subplot(211);
for i=1:numel(iSacStart)
    plot([iSacStart(i)-.5 iSacEnd(i)-.5]*dt,[1 1]*10,'b.-','linewidth',2);
end
subplot(212);
for i=1:numel(iSacStart)
    plot([iSacStart(i)-.5 iSacEnd(i)-.5]*dt,[1 1]*eta_total,'b.-','linewidth',2);
end
xlim([0 10]+2e2)

%% Plot fixations
subplot(211);
for i=1:numel(iFixStart)
    plot([iFixStart(i) iFixEnd(i)-1]*dt,[1 1]*fixPos(1,i),'m.-','linewidth',2);
    plot([iFixStart(i) iFixEnd(i)-1]*dt,[1 1]*fixPos(2,i),'y.-','linewidth',2);
end
% subplot(212);
% for i=1:numel(iSacStart)
%     plot([iSacStart(i)-.5 iSacEnd(i)-.5]*dt,[1 1]*eta_total,'b.-','linewidth',2);
% end
xlim([0 10]+2e2)


%% Plot histograms of durations
xDur = 0:dt:1;
figure(572); clf;
subplot(131);
hist((iBlinkEnd-iBlinkStart)*dt,xDur);
xlabel('blink duration (s)');
ylabel('# blinks');
title(sprintf('%s blinks',filename),'interpreter','none')
xlim([xDur(1) xDur(end)]);
subplot(132);
hist((iSacEnd-iSacStart)*dt,xDur);
xlabel('saccade duration (s)');
ylabel('# saccades');
title(sprintf('%s saccades',filename),'interpreter','none')
xlim([xDur(1) xDur(end)]);
subplot(133);
hist((iFixEnd-iFixStart)*dt,xDur);
xlabel('fixation duration (s)');
ylabel('# fixations');
title(sprintf('%s fixations',filename),'interpreter','none')
xlim([xDur(1) xDur(end)]);

