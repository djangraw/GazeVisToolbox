function h = MakeEyeMovie_simple(samples,pupilsize,times,screen_res,events,timeplot,timeplotlabel)
% Makes a figure/UI for scrolling through eye position data like a movie.
%
% MakeEyeMovie_simple(samples,pupilsize,t,screen_res,events,timeplot,timeplotlabel)
%
% The dot represents the subject's eye position.  The dot's size represents
% the reported pupil size.  The big rectangle is the limits of the screen.
%
% Inputs:
%   - samples is an nx2 matrix, where n is the number of samples of eye
% position data. Each row is the (x,y) position of the eye at that time.
% This will be the position of the dot on the screen.
%   - pupilsize is an n-element vector, where each element is the size of
% the subject's pupil (in unknown units).  This will be the size of the dot
% on the screen.
%   - t is an n-element vector of the corresponding times (in ms).
%   - events is an optional struct including saccade and display fields. In
%   the display field, subfields should be 'time' (in same units as 'times'
%   input),'name' (string), 'type' (optional, for grouping images in bottom
%   timeplot), and 'image' (optional, for display below eye pos... must be
%   image in current path, with same size as screen_res)  
%   - timeplot is a nxr-element matrix indicating the timecourses of r
% arbitrary variables.
%   - timeplotlabel is an r-element cell array of strings labeling the
% timeplot variables.
%
% Outputs:
%   - h is a struct containing the handles for various items on the
% figure.  It can be used to get or change properties of the figures.  For 
% example, type 'get(h.Plot)' to get the properties of the main movie.
%
% Created 8/23/10 by DJ.
% Updated 8/25/10 by DJ - now only 1 click on bottom plot will select time
% Updated 9/1/10 by DJ - object visibility on time plot, target color
%    coding, x is now an input
% Updated 9/14/10 by DJ - added record_time to work with time offsets.
% Updated 5/16/11 by DJ - set any pupilsize NaN values to 1 to avoid error
% Updated 8/9/11 by DJ - added eye calibration
% Updated 2/8/13 by DJ - added saccade plotting, Jump-to-saccade buttons
% Updated 5/6/13 by DJ - added subject/session input format
% Updated ~10/1/15 by DJ - made simple version
% Updated 11/3/15 by DJ - debugging 
% Updated 11/20/15 by DJ - added timeplot and timeplotlabel, more
% intelligent event display, added ability to specify event types and
% images for the display events.
% Updated 12/1/15 by DJ - assume times in ms, modified to show underscores
% in titles/legends.

% -------- INPUTS -------- %
if ~exist('pupilsize','var') || isempty(pupilsize)
    pupilsize=ones(1,length(samples));
end
if ~exist('times','var') || isempty(times)
    times=1:length(samples);
end
if ~exist('screen_res','var') || isempty(screen_res)
    screen_res = [1280, 1024];
end
if ~exist('events','var') || isempty(events);    
    events = struct('display',struct('time',[],'name',{{}}),'saccade',struct('time_start',zeros(0,1),'time_end',zeros(0,1),'position_start',zeros(0,2),'position_end',zeros(0,2)));
end
if ~isfield(events,'display')
    events.display = struct('time',[],'name',{{}});
end
if ~isfield(events,'saccade')
    events.saccade = struct('time_start',zeros(0,1),'time_end',zeros(0,1),'position_start',zeros(0,2),'position_end',zeros(0,2));
end
if ~exist('timeplot','var') || isempty(timeplot)
    timeplot = samples;
    timeplotlabel = {'pos_x','pos_y'};
end
if ~exist('timeplotlabel','var') || isempty(timeplotlabel)
    timeplotlabel = cell(1,size(timeplot));
    for i=1:size(timeplot,2)
        timeplotlabel{i} = sprintf('input %d',i);
    end
end
% -------- SETUP -------- %
% normalize inputs
ps_reg = 50/nanmax(pupilsize); % factor we use to regularize pupil size
t_start = times(1);
times = (times-t_start)/1000;

% Get saccade info
saccade_start_pos = events.saccade.position_start;
saccade_end_pos = events.saccade.position_end;
saccade_times = ([events.saccade.time_start, events.saccade.time_end]-t_start)/1000; %[start end] in s

% Fix NaN problems
pupilsize(isnan(pupilsize)) = 1; % set non-existent pupilsize measures (i.e. during blinks) to tiny dot size

% -------- INITIAL PLOTTING -------- %
disp('Setting up figure...');
figure; % make a new figure
% [~,iTime] = min(abs(time-t_start)); % the global index of the current time point - this is used throughout all functions
iTime = 1;

% Main eye plot
h.Plot = axes('Units','normalized','Position',[0.13 0.3 0.775 0.65],'ydir','reverse'); % set position
hold on;
rectangle('Position',[0 0 screen_res]);
h.Image = image(0,0,cat(3,1,0,1));
h.Dot = plot(samples(iTime,1),samples(iTime,2),'k.','MarkerSize',pupilsize(iTime)*ps_reg);
axis(h.Plot,[-200 screen_res(1)+200 -200 screen_res(2)+200]);
h.Rect = [];
h.iSac = [];
h.Saccade = [];

title(sprintf('t = %.3f s',times(iTime)));

% -------- TIME SELECTION PLOT SETUP -------- %
% 'Time plot' for selecting and observing current time
h.Time = axes('Units','normalized','Position',[0.13 0.1 0.775 0.1],'Yticklabel',''); % set position
hold on
% get event info
event_times = (events.display.time-t_start)/1000;
event_names = events.display.name;
if isfield(events.display,'type')
    event_types = events.display.type;
else
    event_types = repmat({'event'},size(events.display.name));
end
if isfield(events.display,'image')
    event_images = events.display.image;
else
    event_images = repmat({''},size(events.display.name));
end
event_categories = unique(event_types);
% get colors
nTimeplots = size(timeplot,2);
nEventCats = numel(event_categories); 
colors = distinguishable_colors(nTimeplots + nEventCats, {'w','k'});
% plot timeplots
for i=1:nTimeplots
    h.Timeplot{i} = plot(h.Time,times,timeplot(:,i),'ButtonDownFcn',@time_callback);
end
% Make event lines
hEventsCell = cell(nEventCats,1);
% plot colors for legend
for i=1:nEventCats
    plot(-1,-1,'color',colors(i+nTimeplots,:));
end
% plot events for real
for i=1:nEventCats
    hEventsCell{i} = PlotVerticalLines(event_times(strcmp(event_types,event_categories{i})),colors(i+nTimeplots,:));
end
h.Events = cat(2,hEventsCell{:});
set(h.Events,'ButtonDownFcn',@time_callback)

% % Plot saccade times
% plot(saccade_times,ones(size(saccade_times))*0.5,'k+','ButtonDownFcn',@time_callback);
% % Plot eye position
% normalized_samples = nan(size(samples));
% normalized_samples(:,1) = samples(:,1)/screen_res(1);
% normalized_samples(:,2) = samples(:,2)/screen_res(2);
% plot(times,normalized_samples,'g','ButtonDownFcn',@time_callback); % plot eye position

% Make time selection bar
h.Line = plot(times([iTime iTime]), get(gca,'YLim'),'k','linewidth',2); % Line indicating current time
set(h.Time,'ButtonDownFcn',@time_callback) % this must be called after plotting, or it will be overwritten

% Annotate plot
plot([0 times(end)],[0 0],'k','ButtonDownFcn',@time_callback); % plot separation between plots
% ylim(h.Time,[0 1]);
xlim(h.Time,[times(1) times(end)]);
xlabel('time (s)');
ylabel('data/events'); % Top section is object visibility, bottom section is eye x position
legend([timeplotlabel(:);event_categories(:)],'interpreter','none');

% -------- GUI CONTROL SETUP -------- %
disp('Making GUI controls...')
h.Play = uicontrol('Style','togglebutton',...
                'String','Play',...
                'Units','normalized','Position',[.45 .2 .1 .05],...
                'Callback',@play_callback); % play button
h.Speed = uicontrol('Style','slider',...
                'Min',1,'Max',100,'Value',1,'SliderStep',[.05 .2],...
                'Units','normalized','Position',[.45 .25 .1 .025]); % speed slider
h.SacBack = uicontrol('Style','pushbutton',...
                'String','Sac <',...
                'Units','normalized','Position',[.25 .2 .1 .05],...
                'Callback',@sacback_callback); % back-to-last-saccade button
h.Back = uicontrol('Style','pushbutton',...
                'String','<',...
                'Units','normalized','Position',[.38 .2 .05 .05],...
                'Callback',@back_callback); % back button
h.Fwd = uicontrol('Style','pushbutton',...
                'String','>',...
                'Units','normalized','Position',[.57 .2 .05 .05],...
                'Callback',@fwd_callback); % forward button            
h.SacFwd = uicontrol('Style','pushbutton',...
                'String','> Sac',...
                'Units','normalized','Position',[.65 .2 .1 .05],...
                'Callback',@sacfwd_callback); % fwd-to-next-saccade button
              
disp('Done!')
    
% -------- SUBFUNCTIONS -------- %
function redraw() % Update the line and topoplot
    % Check that iTime is within allowable bounds
    if iTime<1, iTime=1;
    elseif iTime>numel(times), iTime = numel(times);
    end
    % Adjust plots
    set(h.Line,'XData',times([iTime iTime]));
    axes(h.Plot);
    if isnan(pupilsize(iTime))
        set(h.Dot,'MarkerSize',0.1)
    else
        set(h.Dot,'XData',samples(iTime,1),'YData',samples(iTime,2),'MarkerSize',pupilsize(iTime)*ps_reg);
    end
    
    % Plot Saccade
    iSaccade = find(times(iTime)>saccade_times(:,1) & times(iTime)<saccade_times(:,2),1);
    if ~isequal(iSaccade,h.iSac)
        delete(h.Saccade);
        h.Saccade = [];
        h.iSac = [];
    end
    if ~isempty(iSaccade) && isempty(h.Saccade)
        saccolor = 'b.-';
        h.Saccade = plot([saccade_start_pos(iSaccade,1) saccade_end_pos(iSaccade,1)], [saccade_start_pos(iSaccade,2) saccade_end_pos(iSaccade,2)], saccolor);        
        h.iSac = iSaccade;    
    end    
    
    % Find event name
    iEvent = find(event_times<=times(iTime),1,'last'); 
    if isempty(iEvent)
        iEvent=0;
        thisEventName = 'None';
    else
        thisEventName = event_names{iEvent};
        % display image
        if isempty(event_images{iEvent})
            set(h.Image,'visible','off')
        else
            cdata = imread(event_images{iEvent});
            set(h.Image,'cdata',cdata,'visible','on')
        end
    end
    
    % Update title
    title(sprintf('t = %.3f s\n Event #%d: %s, Saccade #%d',times(iTime),...
        iEvent,thisEventName,iSaccade),'interpreter','none'); 
    drawnow;
end

function time_callback(hObject,eventdata) % First mouse click on the Time plot brings us here
    cp = get(h.Time,'CurrentPoint'); % get the point(s) (x,y) where the person just clicked
    x = cp(1,1); % choose the x value of one point (the x values should all be the same).
    iTime = find(times>=x,1); % find closest time to the click
    redraw; % update line and topoplot
end    

function play_callback(hObject,eventdata)
    % Get button value
    button_is_on = get(hObject,'Value') == get(hObject,'Max');
    % Keep incrementing and plotting
    while button_is_on && iTime < numel(times) %until we press pause or reach the end
        iTime=iTime+floor(get(h.Speed,'Value'));
        redraw;
        button_is_on = get(hObject,'Value') == get(hObject,'Max');
    end
    set(hObject,'Value',get(hObject,'Min')); % if we've reached the end, turn off the play button
end %function play_callback

function back_callback(hObject,eventdata)
    iTime = iTime-1; % decrement time index
    redraw; % update line and topoplot
end

function fwd_callback(hObject,eventdata)
    iTime = iTime+1; % increment time index
    redraw; % update line and topoplot
end

function sacback_callback(hObject,eventdata)
    saccade = find(saccade_times(:,2)<times(iTime),1,'last');
    if ~isempty(saccade)
        iTime = find(times>saccade_times(saccade,1),1);    
        redraw; % update line and topoplot
    end
end

function sacfwd_callback(hObject,eventdata)
    saccade = find(saccade_times(:,1)>times(iTime),1,'first');
    if ~isempty(saccade)
        iTime = find(times>saccade_times(saccade,1),1);    
        redraw; % update line and topoplot
    end
end


end %function MakeEyeMovie



