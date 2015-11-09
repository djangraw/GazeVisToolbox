function [N,h] = Plot2DHist(data,xHist,yHist)

% [N,h] = Plot2DHist(data,X,Y)
%
% INPUTS:
% -data is an Mx2 matrix of M (x,y) positions.
% -X is an P-element vector indicating the desired x positions in the
% histogram.
% -Y is a Q-element vector indicating the desired y positions in the
% histogram.
%
% OUTPUTS:
% -N is a matrix of size PxQ containing the frequency count for each bin, 
%  in units of %.
% -h is a 3-element vector of the plots created.
%
% Created 7/23/15 by DJ.

N = hist3(data,{xHist,yHist});
N = N/sum(N(:))*100;
clf;

hMain = axes('Position',[.3 .3 .6 .6]);
cla; hold on;
set(gca,'ydir','reverse');
imagesc(xHist,yHist,N');
xlim(xHist([1 end]))
ylim(yHist([1 end]))
colorbar
set(gca,'xticklabel',{},'yticklabel',{});
set(gca,'Position',[.3 .3 .6 .6])
cmap = colormap('gray');
cmap = colormap(1-cmap);
box on
grid on
title('2D histogram')
set(hMain,'layer','top') % put grid on top

hLeft = axes('Position',[.1 .3 .2 .6]);
set(gca,'ydir','reverse','xdir','reverse','xaxislocation','top');
cla; hold on;
nBot = hist(data(:,2),yHist);
nBot = nBot/sum(nBot)*100;
barh(yHist,nBot,1,'k','linestyle','none');
xlabel('% samples')
ylabel('y position')
ylim(yHist([1 end]));
box on
grid on
set(hLeft,'layer','top')

hBot = axes('Position',[.3 .1 .6 .2]);
set(gca,'ydir','reverse','yaxisLocation','right');
cla; hold on;
nLeft = hist(data(:,1),xHist);
nLeft = nLeft/sum(nLeft)*100;
bar(xHist,nLeft,1,'k','linestyle','none');
ylabel('% samples')
xlabel('x position')
xlim(xHist([1 end]));
box on
grid on
set(hBot,'layer','top')

h = [hMain, hBot, hLeft];