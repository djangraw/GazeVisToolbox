function newPositions = ApplyDriftCorrection(positions,times,offsets,tOffsets)

% newPositions = ApplyDriftCorrection(positions,times,offsets,tOffsets)
%
% Created 5/7/15 by DJ based on CorrectDriftOnReadingData.

% Correct fixations
newPositions = positions;
for i=1:numel(tOffsets)
    if i==numel(tOffsets)
        isFix = (times >= tOffsets(i)); 
    else
        isFix = (times >= tOffsets(i) & times < tOffsets(i+1));
    end
    newPositions(isFix,:) = positions(isFix,:) - repmat(offsets(i,:),sum(isFix),1);    
end