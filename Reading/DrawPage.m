function [hText,hBoxes] = DrawPage(words,positions,addboxes,pagedim,fontsize,fontname,fontweight,bgcolor,textcolor)

% hText = DrawPage(words,positions,addboxes,pagedim,fontsize,fontname,fontweight,bgcolor,textcolor)
%
% INPUTS:
% -words is an n-element cell array of strings.
% -positions is an nxm array of numbers, where m>2. positions(i,1:2) is the
% desired (x,y) position of word{i}'s top-left corner.
% -addboxes is a boolean value indicating whether you want boxes drawn
% around the words.
% -pagedim is a 2-element vector indicating the (width,height) size of the
% page/window/axes to be drawn.
% -fontsize, fontname, and fontweight are properties of a text object.
% -bgcolor and textcolor are colorspecs indicating the desired color of the 
% background and text, respectively.
%
% OUTPUTS:
% -hText is an n-element vector of the text objects plotted on the axes.
% -hBoxes is an n-element vector of the rectangles plotted around the words
% (if addboxes is true - otherwise it is a vector of NaNs).
%
% Created 3/25/15 by DJ.
% Updated 4/9/15 by DJ - make page stay where it is.
% Updated 7/27/15 by DJ - put boxes behind text.
% Updated 9/15/15 by DJ - added bgcolor and textcolor inputs.

% Set size/font parameters
if ~exist('addboxes','var') || isempty(addboxes)
    addboxes = false;
end
if ~exist('pagedim','var') || isempty(pagedim)
    pagedim = [1200 700];
end
if ~exist('fontsize','var') || isempty(fontsize)
    fontsize = 50;
end
if ~exist('fontname','var') || isempty(fontname)
    fontname = 'Courier New';
end
if ~exist('fontweight','var') || isempty(fontweight)
    fontweight = 'Bold';
end
if ~exist('bgcolor','var') || isempty(bgcolor)
    bgcolor = 'white';
end
if ~exist('textcolor','var') || isempty(textcolor)
    textcolor = 'black';
end
% Set up figure
clf;
thisPos= get(gcf,'Position');
set(gcf,'Position',[thisPos(1:2), pagedim],'color',bgcolor);
axes('position',[0 0 1 1],'xtick',[],'ytick',[])
hold on;
axis([0, pagedim(1), 0, pagedim(2)]);
set(gca,'xdir','normal','ydir','reverse','visible','off');

% Draw text
hText = nan(size(positions,1),1);
hBoxes = nan(size(positions,1),1);
for i=1:size(positions,1)
    if addboxes
        hBoxes(i) = rectangle('Position',positions(i,:));
    end
    hText(i) = text(positions(i,1),positions(i,2),words{i},...
        'FontName',fontname,'FontSize',fontsize,'FontWeight',fontweight,...
        'VerticalAlignment','cap','HorizontalAlignment','left','color',textcolor);
end