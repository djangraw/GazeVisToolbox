function [fixTime,fixPos] = MatchBinocularFixations(fixTimeL,fixTimeR,fixPosL,fixPosR)

% Created 4/13/15 by DJ.

if iscell(fixTimeL)
    % call recursively
    [fixTime, fixPos] = deal(cell(size(fixTimeL)));
    for i=1:numel(fixTimeL)
        [fixTime{i}, fixPos{i}] = MatchBinocularFixations(fixTimeL{i},fixTimeR{i},fixPosL{i},fixPosR{i});
    end
    return
end


fixTime = nan(0,2);
fixPos = nan(0,2);
iPairs = nan(0,2);
for iL=1:size(fixTimeL,1)
    iOverlapping = find(fixTimeL(iL,1) <= fixTimeR(:,2) & fixTimeR(:,1) <= fixTimeL(iL,2));
    iPairs = [iPairs; repmat(iL,length(iOverlapping),1), iOverlapping];
end
   

isExclusive = false(size(iPairs,1),1);
isMatched = false(size(iPairs,1),1);
iFix = 1;
for iP = 1:size(iPairs,1)
    if isMatched(iP)
        fprintf('iP=%d already matched.\n',iP)
        continue; 
    end
    if sum(iPairs(:,1)==iPairs(iP,1))==1 && sum(iPairs(:,2)==iPairs(iP,2))==1
        isExclusive(iP) = true;
        fixTime(iFix,:) = (fixTimeL(iPairs(iP,1),:) + fixTimeR(iPairs(iP,2),:))/2;
        fixPos(iFix,:) = (fixPosL(iPairs(iP,1),:) + fixPosR(iPairs(iP,2),:))/2;
        iFix = iFix+1;
    else
        if sum(iPairs(:,1)==iPairs(iP,1))==1 % L is exclusive        
            % split L
            iMatch = find(iPairs(:,2)==iPairs(iP,2));
            for iM = 1:numel(iMatch)
                iR = iPairs(iMatch(iM),2);
                if iM==1
                    fixTimeL_this(1) = mean([fixTimeL(iPairs(iP,1),1), fixTimeR(iR,1)]);                    
                else
                    fixTimeL_this(1) = fixTimeR(iR,1);
                end
                if iM==numel(iMatch)
                    fixTimeL_this(2) = mean([fixTimeL(iPairs(iP,1),2), fixTimeR(iR,2)]);
                else
                    fixTimeL_this(2) = fixTimeR(iR,2);
                end
                fixTime(iFix,:) = (fixTimeL_this + fixTimeR(iPairs(iP,2),:))/2;
                fixPos(iFix,:) = (fixPosL(iPairs(iP,1),:) + fixPosR(iPairs(iP,2),:))/2;
                iFix = iFix+1;
            end
        elseif sum(iPairs(:,2)==iPairs(iP,2))==1 % R is exclusive        
            % split R
            iMatch = find(iPairs(:,1)==iPairs(iP,1));
            for iM = 1:numel(iMatch)
                iL = iPairs(iMatch(iM),1);
                if iM==1
                    fixTimeR_this(1) = mean([fixTimeR(iPairs(iP,2),1), fixTimeL(iL,1)]);                    
                else
                    fixTimeR_this(1) = fixTimeL(iL,1);
                end
                if iM==numel(iMatch)
                    fixTimeR_this(2) = mean([fixTimeR(iPairs(iP,2),2), fixTimeL(iL,2)]);
                else
                    fixTimeR_this(2) = fixTimeL(iL,2);
                end
                fixTime(iFix,:) = (fixTimeR_this + fixTimeL(iPairs(iP,1),:))/2;
                fixPos(iFix,:) = (fixPosL(iPairs(iP,1),:) + fixPosR(iPairs(iP,2),:))/2;
                iFix = iFix+1;
            end
        end
        
        isExclusive(iP) = false;
        isMatched(iMatch) = true;
%         fprintf('iP=%d not exclusive\n',iP);    
    end
end
fprintf('All pairs matched! (%d/%d pairs exclusive.)\n',sum(isExclusive),numel(isExclusive));