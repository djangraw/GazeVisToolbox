function [hFig,hText,hBoxes] = PlotPages(data,pagesToPlot,eyesToPlot,figNum,screenSize,imageSize)

% Plot the words, boxes, and eye positions on a given page(s).
%
% hFig = PlotPages(data,pagesToPlot,eyesToPlot,figNum,screenSize,imageSize)
%
% INPUTS:
% -data is a vector of data structs as imported by
% ProcessReadingData_script.
% -pagesToPlot is an n-element vector of the page numbers you want to plot.
% -eyesToPlot is a cell array of strings indicating the eye(s) you want to
% plot (options: 'left','right','matched'[the defualt]).
% -figNum is an n-element vector of the figures you'd like to plot on.
% [300+(1:n)].
% -screenSize is a 2-element vector of the width,height of the screen in
% pixels.
% -imageSize is a 2-element vector of the width,height of the image in
% pixels.
%
% OUTPUTS:
% -hFig is an n-element vector of handles to the figures you've plotted on.
% -hText is an n-element cell array in which cell i is a vector of handles
%  to the words of text on page i.
% -hBoxes is an n-element cell array in which cell i is a vector of handles
%  to the rectangles around all the words on page i.
%
% Created 5/11/15 by DJ.
% Updated 7/27/15 by DJ - added hText and hBoxes output.
% Updated 8/31/15 by DJ - added screenSize input.
% Updated 10/27/15 by DJ - added auto screenSize detection
% Updated 10/30/15 by DJ - removed screenSize input, added figNum input.
% Updated 12/17/15 by DJ - allow imageSize that doesn't match original
% image size
% Updated 2/1/16 by DJ - added AdjustWordPos call
% Updated 8/19/16 by DJ - updated PageTag.

if ~exist('figNum','var') || isempty(figNum)
    figNum = 300+(1:numel(pagesToPlot));
end
if numel(figNum)<numel(pagesToPlot)
    error(sprintf('figNum must be at least %d items long!',numel(pagesToPlot)));
end
% declare default eye to plot
if ~exist('eyesToPlot','var') || isempty(eyesToPlot)
    eyesToPlot = {'right'};
elseif ischar(eyesToPlot)
    eyesToPlot = {eyesToPlot};
end
% add eye field if it doesn't exist
if ~isfield(data(1).events.fixation,'eye')
    for i=1:numel(data)
        data(i).events.fixation.eye = repmat('R',size(data(i).events.fixation.time_start));
    end
end
% declare default screen size
if ~exist('screenSize','var') || isempty(screenSize)
    if isfield(data(1).params,'screenSize')
        screenSize = data(1).params.screenSize;
    else
        screenSize = [1920, 1200];
    end
end
% declare default image size
if ~exist('imageSize','var') || isempty(imageSize)
    if isfield(data(1).params,'imageSize')
        imageSize = str2double(data(1).params.imageSize);
    else
        imageSize = [1201, 945];
    end
end
% get offsets for words to be plotted later
imTopLeft = screenSize/2 - imageSize/2; 
% get pageinfo for all sessions
pageinfo = AppendStructs([data.pageinfo]);
% adjust
pageinfo.cumulativePage = pageinfo.page;
restarts = find(diff(pageinfo.page)<0);
for i=1:numel(restarts)
    pageinfo.cumulativePage(restarts(i)+1:end) = pageinfo.cumulativePage(restarts(i)+1:end) + pageinfo.cumulativePage(restarts(i));
end

% Rescale/adjust wordpos if necessary
if min(pageinfo.pos(:,1))~=imTopLeft(1) % if it hasn't been adjusted yet
    [pageinfo.pos,imScale,imOffset] = AdjustWordPos(pageinfo.pos,imageSize,screenSize);
else    
    imScale = [1 1];
end
% set up
fontSize = 40 * min(imScale);
scaling = 0.3;

% get pageTag
pageTag = 'Page';
% if data(1).params.subject<9
%     pageTag = 'DisplayPage';
% else
%     pageTag = 'Display Page';
% end

% get info
iFile = zeros(size(pagesToPlot));
iPage = zeros(size(pagesToPlot));
[tPageStart, tPageEnd, pageNum] = deal(cell(1,numel(data)));
nPages = zeros(1,numel(data));
for j=1:numel(data)
    [tPageStart{j},tPageEnd{j}, pageNum{j}] = GetPageTimes(data(j).events,pageTag);
    % Convert pageinfo pages to include all pages
    pageNum{j} = pageNum{j} - pageNum{j}(1) + 1 + sum(nPages(1:j-1));
    nPages(j) = numel(pageNum{j});
    [isOnPage, iPageThis] = ismember(pagesToPlot,pageNum{j});
    iFile(isOnPage) = j;
    iPage(isOnPage) = iPageThis(isOnPage);
end

% Plot data
hFig = [];
[hText,hBoxes] = deal(cell(1,numel(pagesToPlot)));
for i=1:numel(pagesToPlot)
    hFig(i) = figure(figNum(i));    
%     [hText{i}, hBoxes{i}] = DrawPage(pageinfo.words(pageinfo.page==pagesToPlot(i)),pageinfo.pos(pageinfo.page==pagesToPlot(i),:)*scaling,true,screenSize*scaling,fontSize*scaling);        
    [hText{i}, hBoxes{i}] = DrawPage(pageinfo.words(pageinfo.cumulativePage==pagesToPlot(i)),pageinfo.pos(pageinfo.cumulativePage==pagesToPlot(i),:)*scaling,true,screenSize*scaling,fontSize*scaling);        
    colormap jet
    shapes = cell(1,numel(eyesToPlot));
    for j=1:numel(eyesToPlot)
        switch lower(eyesToPlot{j})
            case 'matched'                
                fixTime = [data(iFile(i)).events.fixation_matched.time_start, data(iFile(i)).events.fixation_matched.time_end];
                fixPos = data(iFile(i)).events.fixation_matched.position;    
                shapes{j} = 'o';
            case {'left','l'}
                isLeft = upper(data(iFile(i)).events.fixation.eye) == 'L';
                fixTime = [data(iFile(i)).events.fixation.time_start(isLeft), data(iFile(i)).events.fixation.time_end(isLeft)];
                fixPos = data(iFile(i)).events.fixation.position(isLeft,:);    
                shapes{j} = 'd';
            case {'right','r'}
                isRight = upper(data(iFile(i)).events.fixation.eye) == 'R';
                fixTime = [data(iFile(i)).events.fixation.time_start(isRight), data(iFile(i)).events.fixation.time_end(isRight)];
                fixPos = data(iFile(i)).events.fixation.position(isRight,:);    
                shapes{j} = 's';
        end
        isFixOnPage = fixTime(:,1)>tPageStart{iFile(i)}(iPage(i)) & fixTime(:,1)<tPageEnd{iFile(i)}(iPage(i));
        % plot this eye
        plot(fixPos(isFixOnPage,1)*scaling, fixPos(isFixOnPage,2)*scaling, 'color',[1 1 1]*0.8); 
        scatter(fixPos(isFixOnPage,1)*scaling, fixPos(isFixOnPage,2)*scaling,(fixTime(isFixOnPage,2) - fixTime(isFixOnPage,1)),fixTime(isFixOnPage,1),shapes{j}); 
        % expand view a bit
        rectangle('Position',[0,0, screenSize]*scaling);
        axis([-100,screenSize(1)+100, -100,screenSize(2)+100]*scaling);
        thisPos= get(gcf,'Position');
        set(gcf,'Position',[thisPos(1:2), (screenSize+200)*scaling]);
    end
%     MakeLegend(shapes,eyesToPlot,[],[.1 .9]);
    MakeFigureTitle(sprintf('page #%d (%s page %d/%d)',pagesToPlot(i),data(iFile(i)).params.filename,iPage(i),nPages(iFile(i))));
%         pause
end

end