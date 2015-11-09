function [offsetsL, offsetsR, fixPos_corrected, sacStartPos_corrected, sacEndPos_corrected] = CorrectDriftOnReadingData(events,crossPos)

% [offsetsL, offsetsR, fixPos_corrected, sacStartPos_corrected, sacEndPos_corrected] = CorrectDriftOnReadingData(events,crossPos)
%
% INPUTS:
% - events is a data struct imported from a reading task by
% NEDE_ParseEvents.
% - crossPos is a 2-element vector containing the (x,y) position (in screen
% coordinates) of the fixation cross.
%
% OUTPUTS:
% - offsetsL is an Nx2 matrix (where N is the number of pages) in which
% each row is the (x,y) position of the left eye's offset on one trial.
% - offsetsR is the same for the right eye.
% - fixPos_corrected is the result of the correction applied to
% events.fixation.position.
% - sacStartPos_corrected and sacEndPos_corrected are the results of the
% correction applied to events.saccade.position_start and position_end.
% 
%
% Created 5/5/15 by DJ.
% Updated 5/14/15 by DJ - added saccade correction
% Updated 7/2/15 by DJ - added catch if no L or R fixations are found
% within window. Made BOX_SIZE a constant. Added comments.
% Updated 7/28/15 by DJ - added outlier detection/correction.
% Updated 7/30/15 by DJ - added OUTLIER_CUTOFF
% Updated 10/27/15 by DJ - added iFixEnd with DisplayPage tag.

%%

if ~exist('crossPos','var')
    crossPos = [360,265];
end
BOX_SIZE = 200;
OUTLIER_CUTOFF = 100; % if it changes by this much both before and after, the trial is an outlier.

doTrialPlot = false;
% find drift correction periods
iFixEnd = find(strncmp('Display Page',events.message.text,length('Display Page')));
if isempty(iFixEnd)
    iFixEnd = find(strncmp('DisplayPage',events.message.text,length('DisplayPage')));
end
tFixStart = events.message.time(iFixEnd - 1);
tFixEnd = events.message.time(iFixEnd);
% extract info (for brevity)
isLeft = events.fixation.eye=='L';
fixPos = events.fixation.position;
fixDur = events.fixation.time_end - events.fixation.time_start;

[offsetsL, offsetsR] = deal(zeros(numel(tFixStart),2));
for i=1:numel(tFixStart)
    if i==1
        offL = [0,0];
        offR = [0,0];
    else
        offL = offsetsL(i-1,:);
        offR = offsetsR(i-1,:);
    end
    isInTrialL = (events.fixation.time_end>tFixStart(i) & events.fixation.time_start<tFixEnd(i) & isLeft);
    isInTrialR = (events.fixation.time_end>tFixStart(i) & events.fixation.time_start<tFixEnd(i) & ~isLeft);
    isFixL = isInTrialL & abs(fixPos(:,1) - offL(1) - crossPos(1) < BOX_SIZE ...
        & abs(fixPos(:,2) - offL(2) - crossPos(2))<BOX_SIZE);
    isFixR = isInTrialR & abs(fixPos(:,1) - offR(1) - crossPos(1) < BOX_SIZE ...
        & abs(fixPos(:,2) - offR(2) - crossPos(2))<BOX_SIZE);
    fprintf('trial %d: %d fixL and %d fixR in box\n',i,sum(isFixL),sum(isFixR));
%     isFix = (events.fixation.time_end>tFixStart(i) & events.fixation.time_start<tFixEnd(i)...
%         & abs(fixPos(:,1) - crossPos(1))<BOX_SIZE ...
%         & abs(fixPos(:,2) - crossPos(2))<BOX_SIZE);
    % weighted avg (weight fixations by their duration)
%     isFixL = isFix & isLeft;
    % if nothing fell within the window, use the longest fixation.
    if sum(isFixL)==0
        iInTimeWinL = find(events.fixation.time_end>tFixStart(i) & events.fixation.time_start<tFixEnd(i) & isLeft);
        [~,iLongestFixL] = max(events.fixation.time_end(iInTimeWinL) - events.fixation.time_start(iInTimeWinL));
        isFixL(iInTimeWinL(iLongestFixL)) = true;
    end
    weightedAvgPosL = [sum(fixPos(isFixL,1) .* fixDur(isFixL))/sum(fixDur(isFixL)), ...
        sum(fixPos(isFixL,2) .* fixDur(isFixL))/sum(fixDur(isFixL))];
    offsetsL(i,:) = weightedAvgPosL - crossPos;
%     isFixR = isFix & ~isLeft;
    % if nothing fell within the window, use the longest fixation.
    if sum(isFixR)==0
        iInTimeWinR = find(events.fixation.time_end>tFixStart(i) & events.fixation.time_start<tFixEnd(i) & ~isLeft);
        [~,iLongestFixR] = max(events.fixation.time_end(iInTimeWinR) - events.fixation.time_start(iInTimeWinR));
        isFixR(iInTimeWinR(iLongestFixR)) = true;
    end
    weightedAvgPosR = [sum(fixPos(isFixR,1) .* fixDur(isFixR))/sum(fixDur(isFixR)), ...
        sum(fixPos(isFixR,2) .* fixDur(isFixR))/sum(fixDur(isFixR))];
    offsetsR(i,:) = weightedAvgPosR - crossPos;
    if doTrialPlot
        cla; hold on;
        scatter(fixPos(isFixL,1), fixPos(isFixL,2),fixDur(isFixL),'g');
        scatter(fixPos(isFixR,1), fixPos(isFixR,2),fixDur(isFixR),'r');
        plot(weightedAvgPosL(1), weightedAvgPosL(2),'co');
        plot(weightedAvgPosR(1), weightedAvgPosR(2),'mo');
        plot(crossPos(1),crossPos(2),'k+');
%         axis([0,1600, 0,1200]);
        rectangle('Position',[0,0,1600,1200]);
        set(gca,'ydir','reverse');
        title(sprintf('trial %d',i))
        legend('L eye','R eye','R avg','R avg','Fix cross')
%         pause;
    end
end
% Remove outliers
isOutlierL = false(1,numel(tFixStart));
isOutlierR = false(1,numel(tFixStart));
for i=2:numel(tFixStart)-1
    if (abs(offsetsL(i,1) - offsetsL(i-1,1)) > OUTLIER_CUTOFF && abs(offsetsL(i,1) - offsetsL(i+1,1)) > OUTLIER_CUTOFF) || ...
            (abs(offsetsL(i,2) - offsetsL(i-1,2)) > OUTLIER_CUTOFF && abs(offsetsL(i,2) - offsetsL(i+1,2)) > OUTLIER_CUTOFF)
        isOutlierL(i) = true;
    end
    if (abs(offsetsR(i,1) - offsetsR(i-1,1)) > OUTLIER_CUTOFF && abs(offsetsR(i,1) - offsetsR(i+1,1)) > OUTLIER_CUTOFF) || ...
            (abs(offsetsR(i,2) - offsetsR(i-1,2)) > OUTLIER_CUTOFF && abs(offsetsR(i,2) - offsetsR(i+1,2)) > OUTLIER_CUTOFF)
        isOutlierR(i) = true;
    end
end
% save outliers for plotting
oldOffsetsL = offsetsL;
oldOffsetsR = offsetsR;
% correct outliers
offsetsL(isOutlierL,1) = interp1(find(~isOutlierL),offsetsL(~isOutlierL,1),find(isOutlierL));
offsetsL(isOutlierL,2) = interp1(find(~isOutlierL),offsetsL(~isOutlierL,2),find(isOutlierL));
offsetsR(isOutlierR,1) = interp1(find(~isOutlierR),offsetsR(~isOutlierR,1),find(isOutlierR));
offsetsR(isOutlierR,2) = interp1(find(~isOutlierR),offsetsR(~isOutlierR,2),find(isOutlierR));

% Correct fixations
fixPos_corrected = fixPos;
for i=1:numel(tFixStart)
    if i==numel(tFixStart)
        isFix = (events.fixation.time_start >= tFixStart(i)); 
    else
        isFix = (events.fixation.time_start >= tFixStart(i) & events.fixation.time_start < tFixStart(i+1));
    end
    isFixL = isFix & isLeft;
    isFixR = isFix & ~isLeft;
    fixPos_corrected(isFixL,:) = fixPos(isFixL,:) - repmat(offsetsL(i,:),sum(isFixL),1);
    fixPos_corrected(isFixR,:) = fixPos(isFixR,:) - repmat(offsetsR(i,:),sum(isFixR),1);
end

% Correct saccades
sacStartPos = events.saccade.position_start;
sacEndPos = events.saccade.position_start;
isSacL = events.saccade.eye=='L';
sacStartPos_corrected = sacStartPos;
sacStartPos_corrected(isSacL,:) = ApplyDriftCorrection(sacStartPos(isSacL,:), events.saccade.time_start(isSacL),offsetsL,tFixStart);
sacStartPos_corrected(~isSacL,:) = ApplyDriftCorrection(sacStartPos(~isSacL,:), events.saccade.time_start(~isSacL),offsetsR,tFixStart);
sacEndPos_corrected = sacEndPos;
sacEndPos_corrected(isSacL,:) = ApplyDriftCorrection(sacEndPos(isSacL,:), events.saccade.time_end(isSacL),offsetsL,tFixStart);
sacEndPos_corrected(~isSacL,:) = ApplyDriftCorrection(sacEndPos(~isSacL,:), events.saccade.time_end(~isSacL),offsetsR,tFixStart);


%% plot corrections
cla; hold on;
colorOrder = get(gca,'ColorOrder');
plot([offsetsL, offsetsR],'.-');
plot(oldOffsetsL(:,1),':','Color',colorOrder(1,:));
plot(oldOffsetsL(:,2),':','Color',colorOrder(2,:));
plot(oldOffsetsR(:,1),':','Color',colorOrder(3,:));
plot(oldOffsetsR(:,2),':','Color',colorOrder(4,:));
plot(find(isOutlierL),oldOffsetsL(isOutlierL,1),'o','Color',colorOrder(1,:));
plot(find(isOutlierL),oldOffsetsL(isOutlierL,2),'o','Color',colorOrder(2,:));
plot(find(isOutlierR),oldOffsetsR(isOutlierR,1),'o','Color',colorOrder(3,:));
plot(find(isOutlierR),oldOffsetsR(isOutlierR,2),'o','Color',colorOrder(4,:));
xlabel('trial')
ylabel('drift (pixels)')
legend('Lx','Ly','Rx','Ry');