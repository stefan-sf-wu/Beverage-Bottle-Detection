function varargout = ui(varargin)
% UI MATLAB code for ui.fig
%      UI, by itself, creates a new UI or raises the existing
%      singleton*.
%
%      H = UI returns the handle to a new UI or the handle to
%      the existing singleton*.
%
%      UI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in UI.M with the given input arguments.
%
%      UI('Property','Value',...) creates a new UI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ui

% Last Modified by GUIDE v2.5 03-Jun-2019 07:56:58

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @ui_OpeningFcn, ...
    'gui_OutputFcn',  @ui_OutputFcn, ...
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


% --- Executes just before ui is made visible.
function ui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ui (see VARARGIN)

% Choose default command line output for ui
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes ui wait for user response (see UIRESUME)
% uiwait(handles.figure1);

% --- Outputs from this function are returned to the command line.
function varargout = ui_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
set(handles.select,'Enable','off');
try
    load detector.mat
    set(handles.select,'Enable','on');
    set(handles.select,'string','Select Image');
    handles.rcnn = detector;
    guidata(hObject, handles);
catch e %e is an MException struct
    fprintf(1,'The identifier was:\n%s',e.identifier);
    fprintf(1,'There was an error! The message was:\n%s',e.message);
    set(handles.select,'string','Model Error');
end

% --- Executes on button press in select.
function select_Callback(hObject, eventdata, handles)
% hObject    handle to select (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if handles.isfolder.Value == 1
    if isfield(handles, 'filepath')
        fp = uigetdir(handles.filepath, 'Select a Path to Predict');
    else
        fp = uigetdir('', 'Select a Path to Predict');
    end
    if fp == 0
        return;
    end
    f = dir([fp '/*.jpg']);
else
    if isfield(handles, 'filepath')
        [filename, filepath] = uigetfile({'*.png;*.jpg', 'Images'}, 'Select a file to Predict', handles.filepath);
    else
        [filename, filepath] = uigetfile({'*.png;*.jpg', 'Images'}, 'Select a file to Predict');
    end
    if filename == 0
        return;
    end
    f = dir([filepath filename]);
end
set(handles.iscancel, 'Value', 0);
set(handles.select,'Enable','off');
for di = 1 : length(f)
    if handles.iscancel.Value == 1
        break;
    end
    filename = f(di).name;
    filepath = f(di).folder;
    try
        handles.filepath = filepath;
        guidata(hObject, handles);
        I = imread([filepath '/' filename]);
        imshow(I, 'parent', handles.plotimgs);
        set(handles.filename, 'string', filename);
        set(handles.label1, 'string', 'Predicting');
        set(handles.label2, 'string', 'Predicting');
        
        pause(0.5);
        
        [x,y,~] = size(I);
        if x > y
            ratio = 227 / x;
        else
            ratio = 227 / y;
        end
        timg = zeros(227, 227, 3, 'uint8');
        img = imresize(I,[x y] * ratio);
        [x,y,~] = size(img);
        timg(1:x, 1:y, :) = img;
        
        [bboxes, score, label] = detect(handles.rcnn, timg);
        bboxes = bboxes ./ ratio;
        max = 2;
        while true
            [~, id] = maxk(score, max);
            l = label(id);
            if length(l) >= max
                l(2) = l(max);
                if l(1) ~= l(2)
                    id = [id(1) id(max)];
                    break;
                end
                max = max + 1;
            else
                break;
            end
        end
        if length(id) > 1 && (score(id(2)) < 0.5 || l(1) == l(2))
            id = id(1);
        end
        if ~isempty(id)
            annoation = string(label(id(1)));
            set(handles.label1, 'string', sprintf("%s : %f%%", label(id(1)), score(id(1)) * 100));
            if length(id) == 2
                set(handles.label2, 'string', sprintf("%s : %f%%", label(id(2)), score(id(2)) * 100));
                annoation(2,:) = string(label(id(2)));
            else
                set(handles.label2, 'string', '');
            end
            imshow(insertObjectAnnotation(I, 'rectangle', bboxes(id,:), annoation, 'LineWidth', 8, 'FontSize', 40), 'parent', handles.plotimgs);
        else
            set(handles.label1, 'string', 'X');
            set(handles.label2, 'string', 'X');
        end
    catch e %e is an MException struct
        fprintf(1,'%s\n',e.message);
        set(handles.filename, 'string', 'Error loading file');
        set(handles.label1, 'string', 'Error');
        set(handles.label2, 'string', 'Error');
        cla(handles.plotimgs);
    end
    if length(id) > 1
        pause(1);
    else
        pause(0.8);
    end
    
end
set(handles.select,'Enable','on');
set(handles.iscancel, 'Value', 0);

% --- Executes during object creation, after setting all properties.
function plotimgs_CreateFcn(hObject, eventdata, handles)
% hObject    handle to plotimgs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: place code in OpeningFcn to populate plotimgs
axis off;


% --- Executes on button press in isfolder.
function isfolder_Callback(hObject, eventdata, handles)
% hObject    handle to isfolder (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of isfolder


% --- Executes on button press in iscancel.
function iscancel_Callback(hObject, eventdata, handles)
% hObject    handle to iscancel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of iscancel
