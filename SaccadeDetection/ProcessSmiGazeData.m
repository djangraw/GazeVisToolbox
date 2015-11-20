% ProcessSmiGazeData(filename)
%
% Created 8/21/15 by DJ.
% Updated 11/20/15 by DJ - switched to ReadSmiSamples_custom


% Import samples and messages
filename = 'DistractionTask_S1-Samples.txt';
[samples0,messages,paramsRaw] = ReadSmiSamples_custom(filename);
screenSize = str2num(paramsRaw.Calibration.CalibrationArea);
imageSize = [1200, 670];
% convert samples0 to expected format
samples0.POR = [samples0.RPORXpx, samples0.RPORYpx];
samples0.tSample = samples0.Time/1e3; % convert from us to ms
% PD_raw = [samples0.RDiaXpx, samples0.RDiaYpx];



%% record blink times
isBlink = samples0.POR(:,1)==0;
iOneOff = find(isBlink(1:end-2) & ~isBlink(2:end-1) & isBlink(3:end))+1;
isBlink(iOneOff) = true;
iTwoOff = find(isBlink(1:end-3) & ~isBlink(2:end-2) & ~isBlink(3:end-1) & isBlink(4:end))+1;
isBlink([iTwoOff, iTwoOff+1]) = true;
% get blink start and end indices
iBlinkStart = find(diff(isBlink)>0)+1;
iBlinkEnd = find(diff(isBlink)<0);
% expand blinks to include partial occlusion

% create blink time struct
events.blink.time_start = samples0.tSample(iBlinkStart);
events.blink.time_end = samples0.tSample(iBlinkEnd);

% Get outliers
isOutlier = samples0.POR(:,1)<0 | samples0.POR(:,1)>screenSize(1) | ...
    samples0.POR(:,2)<0 | samples0.POR(:,2)>screenSize(2);
% get blink start and end indices
iOutStart = find(diff(isOutlier)>0)+1;
iOutEnd = find(diff(isOutlier)<0);

% expand blinks to include outliers?


%% Zero out blinks
samples = samples0;
fields = fieldnames(samples);
for i=1:numel(fields)
    if ~strcmp(fields{i},'tSample')
        for j=1:size(samples.(fields{i}),2)
            samples.(fields{i})(isBlink,j) = 0;
        end
    end
end

%% plot((samples.tSample-tStart)*1e-6,cat(2,samples.POR,samples.PD,samples.pupilConf,samples.CR));
figure(491); 
subplot(3,1,3); cla;
plot(cat(2,samples.POR,samples.PD,samples.pupilConf,samples.CR));
legend('x (pix)','y (pix)','PDx','PDy','pupilConf','CRx','CRy')
grid on
xlabel('time (samples)')
ylabel('gaze data (see legend)')

%% interpolate blinks and outliers
samples = samples0;
fields = fieldnames(samples);
for i=1:numel(fields)
    if ~strcmp(fields{i},'tSample')
        for j=1:size(samples.(fields{i}),2)
            samples.(fields{i})(isBlink | isOutlier,j) = interp1(samples.tSample(~isBlink & ~isOutlier),samples.(fields{i})(~isBlink & ~isOutlier,j),samples.tSample(isBlink | isOutlier),'linear','extrap');
%             samples.(fields{i})(isBlink,j) = interp1(samples.tSample(~isBlink),samples.(fields{i})(~isBlink,j),samples.tSample(isBlink),'linear','extrap');
%             samples.(fields{i})(isOutlier,j) = interp1(samples.tSample(~isOutlier),samples.(fields{i})(~isOutlier,j),samples.tSample(isOutlier),'linear','extrap');
        end
    end
end

%% Plot x/y and events
iFix = strcmp('DisplayFixation',messages.text);
iPage = strncmp('DisplayPage',messages.text,length('DisplayPage'));
figure(524); cla; hold on;
tStart = samples.tSample(1);
plot(samples.tSample-tStart, samples.POR, '-');
PlotVerticalLines(messages.tMessage(iPage)-tStart,'g--');
PlotVerticalLines(messages.tMessage(iFix)-tStart,'r:');
for i=1:numel(iBlinkStart)
    iBlink = iBlinkStart(i):iBlinkEnd(i); % [iBlinkStart(i), iBlinkEnd(i)] %
    plot(samples.tSample(iBlink)-tStart,samples.POR(iBlink,1),'b','linewidth',2);
    plot(samples.tSample(iBlink)-tStart,samples.POR(iBlink,2),'r','linewidth',2);
end
for i=1:numel(saccadeStruct)
    iSac = [saccadeStruct(i).tStart, saccadeStruct(i).tEnd];
    plot(samples.tSample(iSac)-tStart,samples.POR(iSac,1),'c.:');
    plot(samples.tSample(iSac)-tStart,samples.POR(iSac,2),'m.:');
end
xlabel('time (ms)')
ylabel('position (pix)')
legend('x pos','y pos','pageStart','fixCross','blinks')

%% Detect saccades
% screenSize = [1280, 1024];
dt = median(diff(samples.tSample))/1e3; % convert from us to ms
% KLUGE_CONVERSION = 5000; % somehow convert from pix to degrees
% samplesDeg = samples.sampleRaw * KLUGE_CONVERSION;
KLUGE_CONVERSION = 100;
samplesDeg(:,1) = samples.POR(:,1)*KLUGE_CONVERSION;
samplesDeg(:,2) = (screenSize(2) - samples.POR(:,2))*KLUGE_CONVERSION;
% samplesDeg = SmoothData(samplesDeg',1,'full')';% SMOOTH DATA TO FIGHT JUMPINESS
% rearrange data into Ansh-style structs
[disStruct, velStruct, accStruct] = makeSaccadeDetectorInputStructs(samplesDeg, dt);
threshDis = .1;
threshVel = 100;%45;
threshAcc = 5;%18;
breakFactor = .5;
minDiff = 32/dt;
minSize = 6/dt;
tSacc_eyelink = [0 1];
[saccadeStruct, stats] = saccadeDetector(disStruct, velStruct, accStruct, threshDis, threshVel, threshAcc, breakFactor, minDiff,minSize,tSacc_eyelink);

%% Plot data as movie
% Get word positions and adjust
pageinfo = load('Greeks_Lec02_allpages.mat');
% screenSize = [1280, 1024];
% imageSize = [1200, 670];
imTopLeft = screenSize/2 - imageSize/2; 
pageinfo.pos = pageinfo.pos + [repmat(imTopLeft,size(pageinfo.pos,1),1), zeros(size(pageinfo.pos,1),2)];

% samplesPix(:,1) = (samples.sampleRaw(:,1) - mean(samples.sampleRaw(:,1))) * 100 + 600;
% samplesPix(:,2) = (samples.sampleRaw(:,2) - mean(samples.sampleRaw(:,2))) * 200 + 1300;
samplesPix(:,1) = (samples.POR(:,1));
samplesPix(:,2) = (screenSize(2)-samples.POR(:,2)); % mirror in y direction
% samplesPix = SmoothData(samplesPix',1,'full')';% SMOOTH DATA TO FIGHT JUMPINESS

tSamples = (1:length(samplesPix))*dt; %samples.tSample;%
% events = rmfield(events,'saccade');
events.saccade.time_start = cat(1,saccadeStruct.tStart)*dt;
events.saccade.time_end = cat(1,saccadeStruct.tEnd)*dt;
events.saccade.eye = repmat('L',size(events.saccade.time_end));
events.saccade.position_start(:,1) = interp1(tSamples,samplesPix(:,1),events.saccade.time_start,'linear');
events.saccade.position_start(:,2) = interp1(tSamples,samplesPix(:,2),events.saccade.time_start,'linear');
events.saccade.position_end(:,1) = interp1(tSamples,samplesPix(:,1),events.saccade.time_end,'linear');
events.saccade.position_end(:,2) = interp1(tSamples,samplesPix(:,2),events.saccade.time_end,'linear');
% events.message.time = interp1(samples.tSample,1:length(samples.tSample),messages.tMessage);
events.message.time = (messages.tMessage - tStart)*1e-3;
for i=1:numel(messages.tMessage)
    events.message.text{i} = [messages.text{i}(1:7) ' ' messages.text{i}(8:end)]; % add a space after 'Display'
end

% pupilsize = sqrt(samples.PD(:,1).^2 + samples.PD(:,2).^2);
pupilsize = ones(size(samples.PD(:,1)));
pupilsize(isBlink) = 0.5;
fs = 1000/dt;
MakeEyeMovie_Reading(samplesPix,pupilsize,0,events,pageinfo,'L',fs,screenSize)

%% surround blinks with saccades(?)
iSacStart = [saccadeStruct.tStart];
iSacEnd = [saccadeStruct.tEnd];
isInSac = false(1,numel(iBlinkStart));
for i=1:numel(iBlinkStart)
    % if there are saccades just before and after, combine them
    
    % if there's a saccade just before the blink, expand it to include blink
   
    % if there's a saccade just after the blink, expand it
    
    % if there's no saccade nearby, make a new one around blink.
    
    iStart = find(iSacStart<iBlinkStart(i),1,'last');
    iEnd = find(iSacEnd>iBlinkEnd(i),1,'first');
    if iStart==iEnd
        isInSac(i) = true;
%         fprintf('blink %d = sac %d\n',i,iStart);
    end
end
fprintf('%d/%d = %.1f%% blinks are in saccades\n',sum(isInSac),numel(isInSac),mean(isInSac)*100);


%% Get fixations
nFix = numel(events.saccade.time_start)+1;
% events = rmfield(events,'fixation');
events.fixation.time_start = nan(nFix,1);
events.fixation.time_end = nan(nFix,1);
events.fixation.position = nan(nFix,2);
for i=1:nFix;
    if i==1
        tFixStart = tSamples(1);
        tFixEnd = events.saccade.time_start(i);
    elseif i==nFix
        tFixStart = events.saccade.time_end(i-1);
        tFixEnd = tSamples(end);
    else
        tFixStart = events.saccade.time_end(i-1);
        tFixEnd = events.saccade.time_start(i);
    end
    isInFix = tSamples>=tFixStart & tSamples<=tFixEnd & ~isBlink' & ~isOutlier';        
    if sum(isInFix)>0
        events.fixation.time_start(i) = tSamples(find(isInFix,1,'first'));
        events.fixation.time_end(i) = tSamples(find(isInFix,1,'last'));
        events.fixation.position(i,:) = mean(samples.POR(isInFix,:),1);
    end
end

%% Plot pages
params.filename = filename;
events.fixation.eye = repmat('L',size(events.fixation.time_start));
events.saccade.eye = repmat('L',size(events.saccade.time_start));
data = struct('events',events,'pageinfo',pageinfo,'params',params);
PlotPages(data,16,'left',screenSize);