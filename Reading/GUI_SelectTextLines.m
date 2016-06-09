function varargout = GUI_SelectTextLines(varargin)
% GUI_SELECTTEXTLINES MATLAB code for GUI_SelectTextLines.fig
%
% h = GUI_SelectTextLines(xdata,ydata,iLines,wordpos,times,screenSize)
% 
% INPUTS:
% ALL inputs are an n-element cell array, one for each trial.
% -xdata{i} is an m-element vector of the x coordinates for each fixation.
% -ydata{i} is an m-element vector of the y coordinates for each fixation. 
% -iLines{i} is an m-element vector of the line number to which each
% fixation belongs. 
% -wordpos{i} is a px4 array of the (x,y,width,height) positions of each
% word.
% -times{i} is an m-element vector of the times at which the fixations
% started.
% -screenSize is a 2-element vector of the width,height of the screen.
% [1920, 1200]
% -imageSize is a 2-element vector of the width,height of the image [
% 
% OUTPUTS:
% -h is a handle to the GUI figure; to get handles, use handles=guidata(h).
%
% BUTTONS:
% -Select Points will let you click and drag on the plot to draw a lasso
% around groups of points you want to select.
% -Deselect Points does the same thing, but will change any selected points
% to deselected.
% -Assign will assign the given line number to the selected points.
% -Undo will revert to the previous set of selections (pressing again will
% redo).
% -Show Words turns the word boxes on or off.
%%% -the Show Mask button uses GUI_3View to plot a mask of the selected
% voxels interactively.
% -the Prev/Next Trial buttons move between trials.
%
% Created 7/30/15 by DJ based on GUI_ScatterSelect.
%
%      GUI_SELECTTEXTLINES, by itself, creates a new GUI_SELECTTEXTLINES or raises the existing
%      singleton*.
%
%      H = GUI_SELECTTEXTLINES returns the handle to a new GUI_SELECTTEXTLINES or the handle to
%      the existing singleton*.
%
%      GUI_SELECTTEXTLINES('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in GUI_SELECTTEXTLINES.M with the given input arguments.
%
%      GUI_SELECTTEXTLINES('Property','Value',...) creates a new GUI_SELECTTEXTLINES or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before GUI_SelectTextLines_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to GUI_SelectTextLines_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES
%
% Edit the above text to modify the response to help GUI_SelectTextLines

% Last Modified by GUIDE v2.5 31-Jul-2015 09:54:53

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @GUI_SelectTextLines_OpeningFcn, ...
                   'gui_OutputFcn',  @GUI_SelectTextLines_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

% ======================== %
% ===== I/O FUNCTIONS ==== %
% ======================== %

% --- Executes just before GUI_SelectTextLines is made visible.
function GUI_SelectTextLines_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to GUI_SelectTextLines (see VARARGIN)

% Choose default command line output for GUI_SelectTextLines
handles.output = hObject;

% gather inputs
if nargin>4
    handles.xdata = varargin{1};
    handles.ydata = varargin{2};    
else
    error('>=2 inputs must be provided!');
end
if nargin>5 && ~isempty(varargin{3})
    handles.iLines = varargin{3};
else
    handles.iLines = cell(size(handles.xdata)); 
end
if nargin>6 && ~isempty(varargin{4})
    handles.wordpos = varargin{4};
else
    handles.wordpos = cell(size(handles.xdata)); 
end
if nargin>7 && ~isempty(varargin{5})
    handles.times = varargin{5};
else
    handles.times = cell(size(handles.xdata));     
end    
if nargin>8 && ~isempty(varargin{6})
    handles.offsets = varargin{6};
else
    handles.offsets = repmat({[0,0]},size(handles.xdata));    
end 
if nargin>9 && ~isempty(varargin{7})
    handles.screenSize = varargin{7};
else
    handles.screenSize = [1920, 1200];
end
if nargin>10 && ~isempty(varargin{8})
    handles.imageSize = varargin{8};
else
    handles.imageSize = [1920, 1200];
end
imTopLeft = handles.screenSize/2 - handles.imageSize/2; 
% adjust if necessary
if min(handles.wordpos{1}(:,1))~=imTopLeft(1)
    for i=1:numel(handles.wordpos)
        handles.wordpos{i}(:,1) = handles.wordpos{i}(:,1) + imTopLeft(1);
        handles.wordpos{i}(:,2) = handles.wordpos{i}(:,2) + imTopLeft(2);
    end
end    

% initialize variables
handles.iTrial = 1;
handles.isSelected = false(size(handles.xdata{handles.iTrial}));

% store undo data
handles.wasSelected = handles.isSelected;

% set up lines
handles.nLines = max(max([handles.iLines{:}]),12);
handles.colors = distinguishable_colors(handles.nLines);

% plot data
axes(handles.axes_timecourse); cla; hold on;
axes(handles.axes_points); cla; hold on;
handles.legendstr = cell(1,handles.nLines+1);
for i=1:handles.nLines
    handles.hDots(i) = plot(handles.axes_points, 0,0,'.-','color',handles.colors(i,:)); % for this line
    handles.hDots_t(i) = plot(handles.axes_timecourse,0,0,'.','color',handles.colors(i,:));
    handles.legendstr{i} = sprintf('Line %d',i);
end
handles.hCircles = plot(handles.axes_points,0,0,'ko');
handles.hCircles_t = plot(handles.axes_timecourse,0,0,'ko');
handles.legendstr{end} = 'selected';

% Plot words
handles = PlotWords(handles);

% Update data
PlotData(handles);

% Annotate plot
xlabel(handles.axes_points, 'x pos (pixels)','Interpreter','None');
ylabel(handles.axes_points, 'x pos (pixels)','Interpreter','None');
xlabel(handles.axes_timecourse, 'time (ms)','Interpreter','None');
ylabel(handles.axes_timecourse, 'line #','Interpreter','None');
legend(handles.axes_points, handles.legendstr,'Selected');
set(handles.axes_points,'ydir','reverse','xlim',[0, handles.screenSize(1)],'ylim',[0, handles.screenSize(2)]);
set(handles.axes_timecourse,'ydir','reverse','ylim',[0, handles.nLines+1]);

% SET CONSTANTS
handles.lassothr = diff(get(handles.axes_points,'XLim'))/1000;
handles.SELECT = 1; % select-points mode
handles.DESELECT = 2; % deselect-points mode
handles.MOVE = 3; % move points mode
handles.mode = handles.SELECT;

% Declare keypress function
set(gcf,'KeyPressFcn', @assign_keypress);

% Update handles structure
guidata(hObject, handles);


% UIWAIT makes GUI_SelectTextLines wait for user response (see UIRESUME)
% uiwait(handles.figure1);

% --- Outputs from this function are returned to the command line.
function varargout = GUI_SelectTextLines_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% ======================== %
% ===== SUBFUNCTIONS ===== %
% ======================== %

function PlotData(handles) 

% Update status
set(handles.text_npoints,'string',sprintf('%d points selected',sum(handles.isSelected(:)~=0)));
% Update dots
for i=1:handles.nLines
    set(handles.hDots(i),'xdata',handles.xdata{handles.iTrial}(handles.iLines{handles.iTrial}==i) + handles.offsets{handles.iTrial}(1),'ydata',handles.ydata{handles.iTrial}(handles.iLines{handles.iTrial}==i) + handles.offsets{handles.iTrial}(2));
    set(handles.hDots_t(i),'xdata',handles.times{handles.iTrial}(handles.iLines{handles.iTrial}==i),'ydata',repmat(i,1,sum(handles.iLines{handles.iTrial}==i)));
end
set(handles.hCircles,'xdata',handles.xdata{handles.iTrial}(handles.isSelected) + handles.offsets{handles.iTrial}(1),'ydata',handles.ydata{handles.iTrial}(handles.isSelected) + handles.offsets{handles.iTrial}(2));
set(handles.hCircles_t,'xdata',handles.times{handles.iTrial}(handles.isSelected),'ydata',handles.iLines{handles.iTrial}(handles.isSelected));


function handles = PlotWords(handles)
% plot words
axes(handles.axes_points)
for i=1:size(handles.wordpos{handles.iTrial},1)
    handles.hBox(i) = rectangle('Position', handles.wordpos{handles.iTrial}(i,:));
end
% assign buttondownfcn
if get(handles.toggle_selectpoints,'Value') || get(handles.toggle_deselectpoints,'Value')
    set(handles.hBox,'buttondownfcn',@StartLasso);
elseif get(handles.toggle_move,'Value')
else
    set(handles.hBox,'buttondownfcn',[]);
end
% Turn boxes on or off
if get(handles.toggle_showwords,'Value')
    set(handles.hBox,'Visible','on');
else
    set(handles.hBox,'Visible','off');
end

% ================================== %
% ===== MOUSE BUTTON FUNCTIONS ===== %
% ================================== %
function StartLasso(hObject,eventdata,handles)
handles = guidata(hObject);

% get current point
foo = get(gca,'CurrentPoint');
handles.xy = foo(1,1:2);
if handles.mode == handles.SELECT % select points
    handles.hLasso = plot(handles.xy(:,1),handles.xy(:,2),'m.-');
else % deselect
    handles.hLasso = plot(handles.xy(:,1),handles.xy(:,2),'c.-');
end
% handles.isDown = true;
set(gcf,'WindowButtonMotionFcn',@TraceLasso)
set(gcf,'WindowButtonUpFcn',@StopLasso);
guidata(hObject,handles);


function TraceLasso(hObject,eventdata)
handles = guidata(hObject);
foo = get(gca,'CurrentPoint');    
if norm(foo(1,1:2)-handles.xy(end,:))>handles.lassothr
    handles.xy = [handles.xy; foo(1,1:2)];    
end    

% Update handles structure
guidata(hObject, handles);
set(handles.hLasso,'XData',handles.xy(:,1),'YData',handles.xy(:,2));
drawnow;

function StopLasso(hObject,eventdata)
handles = guidata(hObject);
% handles.isDown=false;
set(gcf,'WindowButtonMotionFcn',[])
set(gcf,'WindowButtonUpFcn',[]);

handles.xy = [handles.xy; handles.xy(1,:)]; % close polygon
set(handles.hLasso,'XData',handles.xy(:,1),'YData',handles.xy(:,2));
drawnow;
if gca==handles.axes_points
    isIn = inpolygon(handles.xdata{handles.iTrial} + handles.offsets{handles.iTrial}(1),handles.ydata{handles.iTrial} + handles.offsets{handles.iTrial}(2),handles.xy(:,1),handles.xy(:,2));
else
    isIn = inpolygon(handles.times{handles.iTrial},handles.iLines{handles.iTrial},handles.xy(:,1),handles.xy(:,2));
end
if ~isempty(isIn)
    handles.wasSelected = handles.isSelected;
    if handles.mode == handles.SELECT
        handles.isSelected(isIn) = true;
    else
        handles.isSelected(isIn) = false;
    end
end
% [handles.hDots,handles.hBox] = PlotData(handles);
PlotData(handles);
delete(handles.hLasso);
% Update handles structure
guidata(hObject, handles);


function StartMove(hObject,eventdata)
handles = guidata(hObject);

% get current point
foo = get(gca,'CurrentPoint');
handles.startPos = foo(1,1:2) - handles.offsets{handles.iTrial};

% handles.isDown = true;
set(gcf,'WindowButtonMotionFcn',@DoMove)
set(gcf,'WindowButtonUpFcn',@StopMove);
guidata(hObject,handles);


function DoMove(hObject,eventdata)
handles = guidata(hObject);
foo = get(gca,'CurrentPoint');    
if norm(foo(1,1:2)-handles.startPos-handles.offsets{handles.iTrial}) > handles.lassothr
    handles.offsets{handles.iTrial} = foo(1,1:2) - handles.startPos;    
end    

% Update handles structure
guidata(hObject, handles);
PlotData(handles);
drawnow;


function StopMove(hObject,eventdata)
set(gcf,'WindowButtonMotionFcn',[])
set(gcf,'WindowButtonUpFcn',[]);


% ======================== %
% ===== UICONTROL FNS ==== %
% ======================== %

% --- Executes on button press in toggle_selectpoints.
function toggle_selectpoints_Callback(hObject, eventdata, handles)
% hObject    handle to toggle_selectpoints (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of toggle_selectpoints

if get(hObject,'Value')
    set(handles.toggle_deselectpoints,'Value',false);
    set(handles.toggle_move,'Value',false);
    set(handles.axes_points,'buttondownfcn',@StartLasso);
    set(handles.hDots,'buttondownfcn',@StartLasso);
    set(handles.hCircles,'buttondownfcn',@StartLasso);
    set(handles.hBox,'buttondownfcn',@StartLasso);
    set(handles.axes_timecourse,'buttondownfcn',@StartLasso);
    set(handles.hDots_t,'buttondownfcn',@StartLasso);
    set(handles.hCircles_t,'buttondownfcn',@StartLasso);    
else
    set(handles.axes_points,'buttondownfcn',[]);
    set(handles.hDots,'buttondownfcn',[]);
    set(handles.hCircles,'buttondownfcn',[]);
    set(handles.hBox,'buttondownfcn',[]);
    set(handles.axes_timecourse,'buttondownfcn',[]);
    set(handles.hDots_t,'buttondownfcn',[]);
    set(handles.hCircles_t,'buttondownfcn',[]);
end
% Update mode
handles.mode = handles.SELECT;
% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in toggle_deselectpoints.
function toggle_deselectpoints_Callback(hObject, eventdata, handles)
% hObject    handle to toggle_deselectpoints (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of toggle_deselectpoints

if get(hObject,'Value')
    set(handles.toggle_selectpoints,'Value',false);
    set(handles.toggle_move,'Value',false);
    set(handles.axes_points,'buttondownfcn',@StartLasso);
    set(handles.hDots,'buttondownfcn',@StartLasso);
    set(handles.hCircles,'buttondownfcn',@StartLasso);
    set(handles.hBox,'buttondownfcn',@StartLasso);
    set(handles.axes_timecourse,'buttondownfcn',@StartLasso);
    set(handles.hDots_t,'buttondownfcn',@StartLasso);
    set(handles.hCircles_t,'buttondownfcn',@StartLasso);
else
    set(handles.axes_points,'buttondownfcn',[]);
    set(handles.hDots,'buttondownfcn',[]);
    set(handles.hCircles,'buttondownfcn',[]);
    set(handles.hBox,'buttondownfcn',[]);
    set(handles.axes_timecourse,'buttondownfcn',[]);
    set(handles.hDots_t,'buttondownfcn',[]);
    set(handles.hCircles_t,'buttondownfcn',[]);
end
% Update mode
handles.mode = handles.DESELECT;
% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in toggle_move.
function toggle_move_Callback(hObject, eventdata, handles)
% hObject    handle to toggle_move (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of toggle_move

if get(hObject,'Value')
    set(handles.toggle_selectpoints,'Value',false);
    set(handles.toggle_deselectpoints,'Value',false);
    set(handles.axes_points,'buttondownfcn',@StartMove);
    set(handles.hDots,'buttondownfcn',@StartMove);
    set(handles.hCircles,'buttondownfcn',@StartMove);
    set(handles.hBox,'buttondownfcn',@StartMove);
    set(handles.axes_timecourse,'buttondownfcn',@StartMove);
    set(handles.hDots_t,'buttondownfcn',@StartMove);
    set(handles.hCircles_t,'buttondownfcn',@StartMove);
else
    set(handles.axes_points,'buttondownfcn',[]);
    set(handles.hDots,'buttondownfcn',[]);
    set(handles.hCircles,'buttondownfcn',[]);
    set(handles.hBox,'buttondownfcn',[]);
    set(handles.axes_timecourse,'buttondownfcn',[]);
    set(handles.hDots_t,'buttondownfcn',[]);
    set(handles.hCircles_t,'buttondownfcn',[]);
end
% Update mode
if get(hObject,'Value')
    handles.mode = handles.MOVE;
end
% Update handles structure
guidata(hObject, handles);

% --- Executes on button press in toggle_showwords.
function toggle_showwords_Callback(hObject, eventdata, handles)
% hObject    handle to toggle_showwords (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of toggle_showwords

if get(hObject,'Value')
    set(handles.hBox,'Visible','on');
else
    set(handles.hBox,'Visible','off');
end


% --- Executes on button press in button_previous.
function button_previous_Callback(hObject, eventdata, handles)
% hObject    handle to button_previous (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% GUI_3View(double(handles.isSelected));

if handles.iTrial == 1
    return;
end

handles.iTrial = handles.iTrial-1;
% Plot words for new page
delete(handles.hBox);
handles.hBox = [];
handles = PlotWords(handles);
% re-plot eye position
PlotData(handles);
% update page number
set(handles.text_page,'String',num2str(handles.iTrial));
% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in button_next.
function button_next_Callback(hObject, eventdata, handles)
% hObject    handle to button_next (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if handles.iTrial == numel(handles.xdata)
    return;
end

handles.iTrial = handles.iTrial+1;
% Plot words for new page
delete(handles.hBox);
handles.hBox = [];
handles = PlotWords(handles);
% re-plot eye position
PlotData(handles);
% update page number
set(handles.text_page,'String',num2str(handles.iTrial));
% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in push_undo.
function push_undo_Callback(hObject, eventdata, handles)
% hObject    handle to push_undo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% swap isSelected and wasSelected.
isS = handles.isSelected;
handles.isSelected = handles.wasSelected;
handles.wasSelected = isS;
% re-plot data
% [handles.hDots,handles.hBox] = PlotData(handles);
PlotData(handles);
if get(handles.toggle_showwords,'Value')
    set(handles.hBox,'Visible','on');
else
    set(handles.hBox,'Visible','off');
end

% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in push_assign.
function push_assign_Callback(hObject, eventdata, handles)
% hObject    handle to push_assign (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

newLine = str2double(get(handles.edit_line,'string'));
if any(1:size(handles.colors,1)==newLine)
    handles.iLines{handles.iTrial}(handles.isSelected) = newLine;
end
handles.isSelected(:) = false;

PlotData(handles);

% Update handles structure
guidata(hObject, handles);


% Allow the user to reassign selected points with a keypress
function assign_keypress(hObject,eventdata)
handles = guidata(hObject);            

% page
if strcmp(eventdata.Key,'leftarrow')
    button_previous_Callback(hObject, eventdata, handles);
    return;
elseif strcmp(eventdata.Key,'rightarrow')
    button_next_Callback(hObject, eventdata, handles);
    return;
elseif strcmp(eventdata.Key,'a')
    handles.isSelected = true(size(handles.xdata{handles.iTrial}));
    guidata(hObject,handles);
    return;
elseif strcmp(eventdata.Key,'n')
    handles.isSelected(:) = false;
    guidata(hObject,handles);
    return;
% add/subtract
elseif strcmp(eventdata.Key,'uparrow')
    newLine = handles.iLines{handles.iTrial}(handles.isSelected) - 1;
elseif strcmp(eventdata.Key,'downarrow')
    newLine = handles.iLines{handles.iTrial}(handles.isSelected) + 1;
% remove 'numpad'
elseif strncmp(eventdata.Key,'numpad',6)
    newLine = str2double(eventdata.Key(7:end));
% get numeric value
else    
    newLine = str2double(eventdata.Key);
end
if isempty(newLine)
    return
elseif newLine==0
    newLine = 10;
end
% reassign
if all(ismember(newLine,1:size(handles.colors,1)))
    handles.iLines{handles.iTrial}(handles.isSelected) = newLine;
end
handles.isSelected(:) = false;

PlotData(handles);

% Update handles structure
guidata(hObject, handles);




function edit_line_Callback(hObject, eventdata, handles)
% hObject    handle to edit_line (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_line as text
%        str2double(get(hObject,'String')) returns contents of edit_line as a double


% --- Executes during object creation, after setting all properties.
function edit_line_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_line (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


