% TestVelocityThresholds_Engbert.m
%
% Created 9/11/15 by DJ.

% BEFORE RUNNING THIS: run some cells from ImportSmiData_Engbert to get
% vel_adj, dt variables. OR load a data struct and run:
dt = median(diff(data(1).events.samples.time));
vel_adj = [zeros(1,2); data(1).events.samples.position]/dt;

%% Scan across velThresh values
minDur = 0;% 33;
minIsi = 50;
velThreshes = 1:.01:6;

[nSac,nInSac,meanSacDur,stdSacDur] = deal(nan(1,numel(velThreshes)));
for i=1:numel(velThreshes)
    [iSacStart,iSacEnd,eta] = GetSaccades_Engbert(vel_adj,dt,minDur,minIsi,velThreshes(i));
    nSac(i) = numel(iSacStart);
    nInSac(i) = sum(iSacEnd-iSacStart);
    meanSacDur(i) = mean(iSacEnd-iSacStart);
    stdSacDur(i) = std(iSacEnd-iSacStart);
end
%% Plot results
figure(261); clf;
subplot(311);
plot(velThreshes,nSac);
xlabel('velocity threshold')
ylabel('# saccades')
subplot(312);
plot(velThreshes,nInSac/length(vel_adj));
xlabel('velocity threshold')
ylabel('frac samples in saccades')
subplot(313);
ErrorPatch(velThreshes(~isnan(stdSacDur)),meanSacDur(~isnan(stdSacDur))*dt,stdSacDur(~isnan(stdSacDur))*dt);
xlabel('velocity threshold')
ylabel('mean saccade dur')
linkaxes(GetSubplots(gcf),'x');
xlim([velThreshes(1) velThreshes(end)])