function [hFig,hText,hBoxes] = PlotPages_samples(data,pagesToPlot,eyesToPlot,figNum,screenSize,imageSize)

% Plot the words, boxes, and eye positions on a given page(s).
%
% hFig = PlotPages_samples(data,pagesToPlot,eyesToPlot,figNum,screenSize,imageSize)
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
% Updated 11/3/15 by DJ - use samples instead of fixations
% Updated 12/17/15 by DJ - allow imageSize that doesn't match original
% image size

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
% get scale of image
origImgSize = max(data(1).pageinfo.pos(:,1:2)+data(1).pageinfo.pos(:,3:4));
imScale = imageSize./origImgSize;

% set up
fontSize = 50 * min(imScale);
scaling = 0.4;
% get pageinfo, offset by top-left of image, and scale by 
pageinfo = AppendStructs([data.pageinfo]);
pageinfo.pos(:,1) = pageinfo.pos(:,1)*imScale(1) + imTopLeft(1);
pageinfo.pos(:,2) = pageinfo.pos(:,2)*imScale(2) + imTopLeft(2);
pageinfo.pos(:,3) = pageinfo.pos(:,3)*imScale(1);
pageinfo.pos(:,4) = pageinfo.pos(:,4)*imScale(2);

% get pageTag
if data(1).params.subject<9
    pageTag = 'DisplayPage';
else
    pageTag = 'Display Page';
end

% get info
iFile = zeros(size(pagesToPlot));
iPage = zeros(size(pagesToPlot));
[tPageStart, tPageEnd, pageNum] = deal(cell(1,numel(data)));
nPages = zeros(1,numel(data));
for j=1:numel(data)
    [tPageStart{j},tPageEnd{j}, pageNum{j}] = GetPageTimes(data(j).events,'DisplayPage');
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
    [hText{i}, hBoxes{i}] = DrawPage(pageinfo.words(pageinfo.page==pagesToPlot(i)),pageinfo.pos(pageinfo.page==pagesToPlot(i),:)*scaling,true,screenSize*scaling,fontSize*scaling);        
    colormap jet
    shapes = cell(1,numel(eyesToPlot));
    for j=1:numel(eyesToPlot)
        switch eyesToPlot{j}
            case {'left','L'}
                isLeft = data(iFile(i)).events.samples.eye == 'L';
                sampleTime = data(iFile(i)).events.samples.time(isLeft);
                samplePos = data(iFile(i)).events.samples.position(isLeft,:);    
                shapes{j} = 'v';
            case {'right','R'}
                isRight = data(iFile(i)).events.samples.eye == 'R';
                sampleTime = data(iFile(i)).events.samples.time(isRight);
                samplePos = data(iFile(i)).events.samples.position(isRight,:);    
                shapes{j} = 'o';
        end
        isSampleOnPage = sampleTime>tPageStart{iFile(i)}(iPage(i)) & sampleTime<tPageEnd{iFile(i)}(iPage(i));
        % plot this eye
        plot(samplePos(isSampleOnPage,1)*scaling, samplePos(isSampleOnPage,2)*scaling, 'color',[1 1 1]*0.8); 
        scatter(samplePos(isSampleOnPage,1)*scaling, samplePos(isSampleOnPage,2)*scaling,...
            20,sampleTime(isSampleOnPage,1),shapes{j},'filled'); 
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