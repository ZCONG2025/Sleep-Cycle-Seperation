classdef MainApp < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure               matlab.ui.Figure
        GridLayout             matlab.ui.container.GridLayout
        LeftPanel              matlab.ui.container.Panel
        TabGroup               matlab.ui.container.TabGroup
        CyclesTab              matlab.ui.container.Tab
        CurrentCycleTable      matlab.ui.control.Table
        ClearButton            matlab.ui.control.Button
        SubjectsTab            matlab.ui.container.Tab
        SubjectList            matlab.ui.control.ListBox
        DatasetsTab            matlab.ui.container.Tab
        DatasetList            matlab.ui.control.ListBox
        AutosaveSwitchLabel    matlab.ui.control.Label
        AutosaveSwitch         matlab.ui.control.Switch
        CreateNewButton     matlab.ui.control.Button
        LoadExistingSetButton  matlab.ui.control.Button
        RightPanel             matlab.ui.container.Panel
        Hypnogram              matlab.ui.control.UIAxes
        NextButton             matlab.ui.control.Button
        ManualButton           matlab.ui.control.StateButton
        StartXLabel            matlab.ui.control.Label
        StartYLabel            matlab.ui.control.Label
        AddButton              matlab.ui.control.Button
        SubjectNameLabel       matlab.ui.control.Label
        PreviousSubject        matlab.ui.control.Button
        NextSubject            matlab.ui.control.Button
        DeleteButton           matlab.ui.control.Button
        StartPointLabel        matlab.ui.control.Label
        EndXLabel              matlab.ui.control.Label
        EndYLabel              matlab.ui.control.Label
        EndPointLabel          matlab.ui.control.Label
    end

    % Properties that correspond to apps with auto-reflow
    properties (Access = private)
        onePanelWidth = 576;
    end

    
    properties (Access = public) %这里存放的是所有Subject的Summary变量，可通过app.CurrentNumOfSUbject抓取
        %1st level: load data
        freq=200;
        Len=6000;
        channelist =['C3';'C4';'O1';'O2';'F3';'F4'];
        isImport=0;
        
        %2nd level: sum of all datasets
        DataSetList; %include: name, freq, step, Input
        NumOfDataSet=0;
        CurrentNumOfDataSet=0;
        
        %3nd level: sum of subjects in current dataset
        Input;
        NameOfSet;
        info;%Hypno
        NumOfSubject=0;
        SumOfCycle=[];
        SumOfCycleDetail=[];
        CurrentNumOfDataset=1;
       % ResultOfCycle=[];
        FileNames;
        isLabelled;     %IMPORTANT: decide whether a subject has been labelled(default: 0). 
                        %Even a subject has cycle information, it could still be nulled by this.
        isAutoSave=1;
        isAutoLabel=1;  %AutoLabel功能将自动选取一些点位，比如下一个cycle的start point自动选择为上一个cycle的endpoint
                        %End point会吸附到该stage（通常为REM）的最远端；后续会添加更多自动化功能
    end
    
    properties (Access = private) %这里面存放针对当前Subject的临时变量，通常在Subject改变时就会清空
        %1st level: path select window
        IOApp;
        %2nd level: current dataset information
        
        EventList;
        ALLEEG;             %后续增加功能：选择是否一次性将所有数组load进来（取决于计算机性能）
        %3rd level: current subject information
        CurrentNumOfSubject=1;
        EEG1;
        NumOfCycle=0;
        CycleDetail=[];
        EOF=0;%如果最后一个cycle的end point已经标到结尾则为1
        %4th level: current sleep cycle information
        Start;
        End;
        isSetValueStart=0;   %重要！！决定Start或End点是否已经确定值（防止Current Point框继续刷新点位）
        isSetValueEnd=0;     %后续增加Clear按钮以继续刷新坐标值
        
    end

    
    methods (Access = private)
        function Prep0(app)      %初始化，读取文件列表
            Length_Names = length(app.FileNames);
            app.NumOfSubject=Length_Names;
            app.SubjectList.Items=app.FileNames;
            app.SubjectList.ItemsData=[1:Length_Names];
        end
        
        function Prep1(app, Num) %Num的含义是第几个Subject，通过app.CurrentNumOfSubject实例化
            Filename=app.FileNames(Num);
            filepath=strcat(app.Input, Filename);
            Name=Filename{1};
            EEG=pop_loadset('filename', Name,'filepath',app.Input);
            
            %initialize data
              app.freq=EEG.srate;
             Name=erase(Name, '.set');
             app.SubjectNameLabel.Text=Name;
             %Extract Latency & Hypno
             num=length(EEG.event);
            for i=1:num
                latency(i)=EEG.event(i).latency;
                Hypno(i)=EEG.event(i).type;
            end
             app.EventList=[latency',Hypno'];
             
             %Print data
             scale=3600; %Control the x label based on the data
             HypnoEndTime=latency(end)/app.freq;
             FirstEndTime=floor(HypnoEndTime/scale)*scale*app.freq;
             app.Hypnogram.XTick=[0:scale*app.freq:FirstEndTime, EEG.pnts];
             Label={};
             for i=0:floor(HypnoEndTime/scale)
                 Label(i+1)= {TimeConvert(app, i*scale)};
             end
             Label(end+1)={'EEG End'};
             app.Hypnogram.XTickLabel=Label;
             app.Hypnogram.XTickLabelRotation=90;
             plot(app.Hypnogram,latency, Hypno, 'Tag','Hypno');
             
             if app.isAutoLabel
                app.Start=latency(1)/app.freq;%此处给出了每次载入新subject的start点初值，同时清空end点
                app.isSetValueStart=1;
                UpdatePointValue(app,0,0);
             else
                 app.Start=0;
             end
             app.isSetValueEnd=0;
             app.End=0;
        end
        
        function StateChange(app, Num)
           Prep1(app, Num);
           if app.isLabelled(Num) %if contains valid information
                app.NumOfCycle=app.SumOfCycle(Num);
                app.CycleDetail=app.SumOfCycleDetail(Num).CycleDetail;
                app.CurrentCycleTable.Data=[1:app.NumOfCycle;app.CycleDetail(:,1)';app.CycleDetail(:,2)']';
           else 
               app.NumOfCycle=0;
               app.CycleDetail=[];
               app.CurrentCycleTable.Data=[];
           end
        end
        
        function Time=TimeConvert(app, time) %input time in seconds and return Time in String
           
            hours = floor(time  /(60 * 60));
            time = time - hours * (60 * 60);
 
            minutes = floor(time / 60);
            time = time-minutes * 60;
 
            seconds = time;
            
            Time = strcat(num2str(hours),'h ',num2str(minutes),'min'); 
        end
        
        function UpdatePointValue(app, index1, index2) 
            if nargin < 3
                index2=0;
            end  
            if index2==1 && index1==0
                    app.StartXLabel.Text = 'NaN';
                    app.StartYLabel.Text = 'NaN';
            else
                if index2==1 && index1==1
                    app.EndXLabel.Text = 'NaN';
                    app.EndYLabel.Text = 'NaN';
                else
                    if index1==0    %Start pt
                        index=find(app.EventList(:,1)==app.Start*app.freq);
                        app.StartXLabel.Text = num2str(app.Start);
                        app.StartYLabel.Text = num2str(app.EventList(index, 2));
                    else 
                        if index1==1    %end pt
                            index=find(app.EventList(:,1)==app.End*app.freq);
                            app.EndXLabel.Text = num2str(app.End);
                            app.EndYLabel.Text = num2str(app.EventList(index, 2));
                        end
                    end
                end
            end
        end

        function AutoChange(app) %自动贴靠
            if app.isAutoLabel && app.EOF==0                           %当autolabel打开时允许end point自动贴靠
                index=find(app.EventList(:,1)==app.End*app.freq);
                yp=app.EventList(index,2);
                    while 1
                        if index+1<length(app.EventList)
                            if app.EventList(index+1,2)==yp
                                index=index+1;
                            else 
                                app.End=app.EventList(index,1)/app.freq;
                                break;
                            end
                        else 
                            app.EOF=1;
                            break;
                        end
                    end
             end
        end
        
    end
        
    methods (Access = public)
        
         function Prep(app)      %初始化，读取文件列表
            app.DatasetList.Items=cellstr(app.DataSetList.NameOfSet);
            app.DatasetList.ItemsData=[1:app.NumOfDataSet];
         end
        
        function initialization(app)
            
            %!! 此处添加导入有效性检查
           app.NameOfSet = app.DataSetList(app.CurrentNumOfDataSet).NameOfSet;
            app.Input=app.DataSetList(app.CurrentNumOfDataSet).Input;
            app.FileNames=app.DataSetList(app.CurrentNumOfDataSet).FileNames;
            
            
            Prep0(app); %显示第一个subject
            Prep1(app, 1);
            app.isLabelled=zeros(1,app.NumOfSubject);
            app.SumOfCycle=zeros(1,app.NumOfSubject);
        end
    end


    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            app.DatasetList.Items={''};
            app.SubjectList.Items={''};
            app.AutosaveSwitch.ItemsData=[0 1];
        end

        % Button pushed function: CreateNewButton
        function CreateNewButtonPushed(app, event)
             % Disable Plot Options button while dialog is open
            app.CreateNewButton.Enable = 'off';
            
            % Open the options dialog and pass inputs
            app.IOApp = CreateNew(app);
          
        end

        % Button pushed function: LoadExistingSetButton
        function LoadExistingSetButtonPushed(app, event)
            % Disable Plot Options button while dialog is open
            app.LoadExistingSetButton.Enable = 'off';
            
            % Open the options dialog and pass inputs
            app.IOApp = LoadExistingSet(app);
        end

        % Window button motion function: UIFigure
        function UIFigureWindowButtonMotion(app, event)
            if app.isImport
            currPt = app.Hypnogram.CurrentPoint;
            xp = currPt(1,1);
            yp = currPt(1,2);
            if app.isSetValueStart==0 % 当鼠标离开坐标区时，X,Y编辑框显示为0
            if xp < app.Hypnogram.XLim(1,1)||...
                    xp > app.Hypnogram.XLim(1,2)||...
                    yp < app.Hypnogram.YLim(1,1)||...
                    yp > app.Hypnogram.YLim(1,2)    
                return
            end
            
            [~,StartIndex]=min(abs(app.EventList(:,1)-xp));
            app.Start=double(app.EventList(StartIndex,1))/app.freq;
            UpdatePointValue(app, 0);

               
            else 
                if app.isSetValueEnd==0 % 当鼠标离开坐标区时，X,Y编辑框显示为0
                    if xp < app.Hypnogram.XLim(1,1)||...
                    xp > app.Hypnogram.XLim(1,2)||...
                    yp < app.Hypnogram.YLim(1,1)||...
                    yp > app.Hypnogram.YLim(1,2)
                return
                    end
            
            [~,EndIndex]=min(abs(app.EventList(:,1)-xp));
            app.End=double(app.EventList(EndIndex,1))/app.freq;
               UpdatePointValue(app, 1);
                end
            end
            end
        end

        % Window button down function: UIFigure
        function UIFigureWindowButtonDown(app, event)
            if app.isImport
            currPt = app.Hypnogram.CurrentPoint;
            xp = currPt(1,1);
            yp = currPt(1,2);
            if app.isSetValueStart==0 % 当鼠标离开坐标区时，X,Y编辑框显示为0
            if xp < app.Hypnogram.XLim(1,1)||...
                    xp > app.Hypnogram.XLim(1,2)||...
                    yp < app.Hypnogram.YLim(1,1)||...
                    yp > app.Hypnogram.YLim(1,2)    
                return
            end
            
            [~,StartIndex]=min(abs(app.EventList(:,1)-xp));
            app.Start=double(app.EventList(StartIndex,1))/app.freq;
            UpdatePointValue(app, 0);
            app.isSetValueStart=1;
               
            else 
                if app.isSetValueEnd==0 % 当鼠标离开坐标区时，X,Y编辑框显示为0
                    if xp < app.Hypnogram.XLim(1,1)||...
                    xp > app.Hypnogram.XLim(1,2)||...
                    yp < app.Hypnogram.YLim(1,1)||...
                    yp > app.Hypnogram.YLim(1,2)
                return
                    end
            
            [~,EndIndex]=min(abs(app.EventList(:,1)-xp));
            app.End=double(app.EventList(EndIndex,1))/app.freq;
                AutoChange(app);
                UpdatePointValue(app, 1);
               app.isSetValueEnd=1;
                end
            end
            end
        end

        % Button pushed function: NextButton
        function NextButtonPushed(app, event)
            %IMPORTANT: Only press Next will save current data
            app.SumOfCycleDetail(app.CurrentNumOfSubject).Name=app.SubjectNameLabel.Text; 
            app.SumOfCycleDetail(app.CurrentNumOfSubject).CycleDetail=app.CycleDetail;
            app.SumOfCycle(app.CurrentNumOfSubject)=app.NumOfCycle;
            app.CurrentNumOfSubject=app.CurrentNumOfSubject+1;
            if app.CurrentNumOfSubject>app.NumOfSubject
                app.CurrentNumOfSubject=app.CurrentNumOfSubject-1; %这里需要添加一个到结尾警告
            end
            StateChange(app, app.CurrentNumOfSubject);
            if app.isAutoSave
                freq=app.freq;
                Len=app.Len;
                Input=app.Input;
                channelist=app.channelist;
                info=app.info;
                NumOfSubject=app.NumOfSubject;
                SumOfCycle=app.SumOfCycle;
                SumOfCycleDetail=app.SumOfCycleDetail;
                FileNames=app.FileNames;
                isLabelled=app.isLabelled;
                save(strcat(app.NameOfSet, '.mat'), 'freq','Len','Input','channelist','NumOfSubject','SumOfCycle',...
                    'SumOfCycleDetail','FileNames','isLabelled');
            end
            app.EOF=0;
        end

        % Button pushed function: AddButton
        function AddButtonPushed(app, event)
            if app.isSetValueEnd==1 && app.isSetValueStart==1
                app.CycleDetail=[app.CycleDetail;app.Start app.End];
                index=find(app.EventList(:,1)==app.End*app.freq);
                if app.EOF==0
                    app.Start=app.EventList(index+1,1)/app.freq;
                else 
                    UpdatePointValue(app, 0,1);
                end
                app.NumOfCycle=app.NumOfCycle+1;
                app.CurrentCycleTable.Data=[1:app.NumOfCycle;app.CycleDetail(:,1)';app.CycleDetail(:,2)']';
                app.isLabelled(app.CurrentNumOfSubject)=1;
                %成功add一个cycle后，重置以下参量
                if app.isAutoLabel
                    if app.EOF==0
                    app.isSetValueStart=1;
                    StartIndex=find(app.EventList(:,1)==app.End*app.freq)+1;
                    app.Start=app.EventList(StartIndex,1)/app.freq;
                    app.isSetValueStart=1;
                    UpdatePointValue(app, 0);
                    else 
                        app.Start=0;
                        UpdatePointValue(app, 0,1);
                    end
                    app.isSetValueEnd=0;
                    
                else
                    app.isSetValueEnd=0;
                    app.isSetValueStart=0;
                    app.EndXLabel.Text = num2str(0);
                    app.EndYLabel.Text = num2str(0);
                end
            end
            %!!这里需要添加警告：当start和end值没有同时设置时，Add键无反应
        end

        % Button pushed function: NextSubject
        function NextSubjectButtonPushed(app, event)
            
            app.CurrentNumOfSubject=app.CurrentNumOfSubject+1;

            if app.CurrentNumOfSubject>app.NumOfSubject
                app.CurrentNumOfSubject=app.CurrentNumOfSubject-1; %这里需要添加一个到结尾警告
            end
            StateChange(app, app.CurrentNumOfSubject);
        end

        % Button pushed function: PreviousSubject
        function PreviousSubjectButtonPushed(app, event)
            app.CurrentNumOfSubject=app.CurrentNumOfSubject-1;

            if app.CurrentNumOfSubject<0
                app.CurrentNumOfSubject=app.CurrentNumOfSubject+1; %这里需要添加一个到开头警告
            end
            StateChange(app, app.CurrentNumOfSubject);
            
        end

        % Value changed function: AutosaveSwitch
        function AutosaveSwitchValueChanged(app, event)
            value = app.AutosaveSwitch.Value;
            if value==1
                app.isAutoSave=1;
            else
                app.isAutoSave=0;
            end
        end

        % Close request function: UIFigure
        function UIFigureCloseRequest(app, event)
            
            delete(app.IOApp);
            delete(app);
        end

        % Button pushed function: DeleteButton
        function DeleteButtonPushed(app, event)
            % !!delete只为了已经选好start和end但还没press add的情况使用
            if ~app.isAutoLabel
                app.isSetValueStart=0;
                UpdatePointValue(app,0,1);
            end
            app.isSetValueEnd=0;
            UpdatePointValue(app,1,1);
        end

        % Button pushed function: ClearButton
        function ClearButtonPushed(app, event)
            app.NumOfCycle=0;
            app.EOF=0;
            app.CycleDetail=[];
            app.SumOfCycle(app.CurrentNumOfSubject)=0;
            app.SumOfCycleDetail(app.CurrentNumOfSubject).CycleDetail=[];
            app.CurrentCycleTable.Data=[];
            app.isLabelled(app.CurrentNumOfSubject)=0;
            Prep1(app,app.CurrentNumOfSubject);
        end

        % Value changed function: SubjectList
        function SubjectListValueChanged(app, event)
            app.CurrentNumOfSubject = app.DatasetList.Value;
            StateChange(app, app.CurrentNumOfSubject);
        end

        % Value changed function: DatasetList
        function DatasetListValueChanged(app, event)
            app.CurrentNumOfDataset=app.DatasetList.Value;
            initialization(app);
        end

        % Changes arrangement of the app based on UIFigure width
        function updateAppLayout(app, event)
            currentFigureWidth = app.UIFigure.Position(3);
            if(currentFigureWidth <= app.onePanelWidth)
                % Change to a 2x1 grid
                app.GridLayout.RowHeight = {799, 799};
                app.GridLayout.ColumnWidth = {'1x'};
                app.RightPanel.Layout.Row = 2;
                app.RightPanel.Layout.Column = 1;
            else
                % Change to a 1x2 grid
                app.GridLayout.RowHeight = {'1x'};
                app.GridLayout.ColumnWidth = {343, '1x'};
                app.RightPanel.Layout.Row = 1;
                app.RightPanel.Layout.Column = 2;
            end
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.AutoResizeChildren = 'off';
            app.UIFigure.Position = [100 100 1269 799];
            app.UIFigure.Name = 'MATLAB App';
            app.UIFigure.CloseRequestFcn = createCallbackFcn(app, @UIFigureCloseRequest, true);
            app.UIFigure.SizeChangedFcn = createCallbackFcn(app, @updateAppLayout, true);
            app.UIFigure.WindowButtonDownFcn = createCallbackFcn(app, @UIFigureWindowButtonDown, true);
            app.UIFigure.WindowButtonMotionFcn = createCallbackFcn(app, @UIFigureWindowButtonMotion, true);

            % Create GridLayout
            app.GridLayout = uigridlayout(app.UIFigure);
            app.GridLayout.ColumnWidth = {343, '1x'};
            app.GridLayout.RowHeight = {'1x'};
            app.GridLayout.ColumnSpacing = 0;
            app.GridLayout.RowSpacing = 0;
            app.GridLayout.Padding = [0 0 0 0];
            app.GridLayout.Scrollable = 'on';

            % Create LeftPanel
            app.LeftPanel = uipanel(app.GridLayout);
            app.LeftPanel.Layout.Row = 1;
            app.LeftPanel.Layout.Column = 1;

            % Create TabGroup
            app.TabGroup = uitabgroup(app.LeftPanel);
            app.TabGroup.Position = [7 1 336 366];

            % Create CyclesTab
            app.CyclesTab = uitab(app.TabGroup);
            app.CyclesTab.Title = 'Cycles';

            % Create CurrentCycleTable
            app.CurrentCycleTable = uitable(app.CyclesTab);
            app.CurrentCycleTable.ColumnName = {'Number'; 'Start'; 'End'};
            app.CurrentCycleTable.RowName = {};
            app.CurrentCycleTable.Position = [16 143 303 175];

            % Create ClearButton
            app.ClearButton = uibutton(app.CyclesTab, 'push');
            app.ClearButton.ButtonPushedFcn = createCallbackFcn(app, @ClearButtonPushed, true);
            app.ClearButton.BackgroundColor = [0.9608 0.2118 0.2118];
            app.ClearButton.FontColor = [1 1 1];
            app.ClearButton.Position = [219 88 100 24];
            app.ClearButton.Text = 'Clear';

            % Create SubjectsTab
            app.SubjectsTab = uitab(app.TabGroup);
            app.SubjectsTab.Title = 'Subjects';

            % Create SubjectList
            app.SubjectList = uilistbox(app.SubjectsTab);
            app.SubjectList.ValueChangedFcn = createCallbackFcn(app, @SubjectListValueChanged, true);
            app.SubjectList.Position = [16 122 286 196];

            % Create DatasetsTab
            app.DatasetsTab = uitab(app.TabGroup);
            app.DatasetsTab.Title = 'Datasets';

            % Create DatasetList
            app.DatasetList = uilistbox(app.DatasetsTab);
            app.DatasetList.ValueChangedFcn = createCallbackFcn(app, @DatasetListValueChanged, true);
            app.DatasetList.Position = [16 122 286 196];

            % Create AutosaveSwitchLabel
            app.AutosaveSwitchLabel = uilabel(app.LeftPanel);
            app.AutosaveSwitchLabel.HorizontalAlignment = 'center';
            app.AutosaveSwitchLabel.VerticalAlignment = 'top';
            app.AutosaveSwitchLabel.Position = [184 379 55 22];
            app.AutosaveSwitchLabel.Text = 'Autosave';

            % Create AutosaveSwitch
            app.AutosaveSwitch = uiswitch(app.LeftPanel, 'slider');
            app.AutosaveSwitch.ValueChangedFcn = createCallbackFcn(app, @AutosaveSwitchValueChanged, true);
            app.AutosaveSwitch.Position = [262 383 41 18];
            app.AutosaveSwitch.Value = 'On';

            % Create CreateNewButton
            app.CreateNewButton = uibutton(app.LeftPanel, 'push');
            app.CreateNewButton.ButtonPushedFcn = createCallbackFcn(app, @CreateNewButtonPushed, true);
            app.CreateNewButton.Position = [57 647 108 22];
            app.CreateNewButton.Text = 'Create New Set';

            % Create LoadExistingSetButton
            app.LoadExistingSetButton = uibutton(app.LeftPanel, 'push');
            app.LoadExistingSetButton.ButtonPushedFcn = createCallbackFcn(app, @LoadExistingSetButtonPushed, true);
            app.LoadExistingSetButton.Position = [57 593 108 22];
            app.LoadExistingSetButton.Text = {'Load Existing Set'; ''};

            % Create RightPanel
            app.RightPanel = uipanel(app.GridLayout);
            app.RightPanel.Layout.Row = 1;
            app.RightPanel.Layout.Column = 2;

            % Create Hypnogram
            app.Hypnogram = uiaxes(app.RightPanel);
            title(app.Hypnogram, '')
            xlabel(app.Hypnogram, 'Time')
            ylabel(app.Hypnogram, 'Stage')
            app.Hypnogram.FontSize = 10;
            app.Hypnogram.XTick = [0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1];
            app.Hypnogram.YTick = [0 1 2 3 4];
            app.Hypnogram.YTickLabel = {'Awake'; 'N1'; 'N2'; 'N3'; 'REM'};
            app.Hypnogram.TitleFontWeight = 'bold';
            app.Hypnogram.Position = [31 168 864 511];

            % Create NextButton
            app.NextButton = uibutton(app.RightPanel, 'push');
            app.NextButton.ButtonPushedFcn = createCallbackFcn(app, @NextButtonPushed, true);
            app.NextButton.BackgroundColor = [0 0 1];
            app.NextButton.FontColor = [1 1 1];
            app.NextButton.Position = [786 58 100 22];
            app.NextButton.Text = 'Next';

            % Create ManualButton
            app.ManualButton = uibutton(app.RightPanel, 'state');
            app.ManualButton.Text = 'Manual';
            app.ManualButton.Position = [786 101 100 22];

            % Create StartXLabel
            app.StartXLabel = uilabel(app.RightPanel);
            app.StartXLabel.HorizontalAlignment = 'right';
            app.StartXLabel.Position = [64 102 66 22];
            app.StartXLabel.Text = {'StartX'; ''};

            % Create StartYLabel
            app.StartYLabel = uilabel(app.RightPanel);
            app.StartYLabel.Position = [157 102 39 22];
            app.StartYLabel.Text = 'StartY';

            % Create AddButton
            app.AddButton = uibutton(app.RightPanel, 'push');
            app.AddButton.ButtonPushedFcn = createCallbackFcn(app, @AddButtonPushed, true);
            app.AddButton.Position = [99 58 100 22];
            app.AddButton.Text = 'Add';

            % Create SubjectNameLabel
            app.SubjectNameLabel = uilabel(app.RightPanel);
            app.SubjectNameLabel.Position = [425 703 77 22];
            app.SubjectNameLabel.Text = 'SubjectName';

            % Create PreviousSubject
            app.PreviousSubject = uibutton(app.RightPanel, 'push');
            app.PreviousSubject.ButtonPushedFcn = createCallbackFcn(app, @PreviousSubjectButtonPushed, true);
            app.PreviousSubject.Position = [86 703 44 22];
            app.PreviousSubject.Text = '<';

            % Create NextSubject
            app.NextSubject = uibutton(app.RightPanel, 'push');
            app.NextSubject.ButtonPushedFcn = createCallbackFcn(app, @NextSubjectButtonPushed, true);
            app.NextSubject.Position = [786 703 44 22];
            app.NextSubject.Text = '>';

            % Create DeleteButton
            app.DeleteButton = uibutton(app.RightPanel, 'push');
            app.DeleteButton.ButtonPushedFcn = createCallbackFcn(app, @DeleteButtonPushed, true);
            app.DeleteButton.Position = [232 58 100 22];
            app.DeleteButton.Text = 'Delete';

            % Create StartPointLabel
            app.StartPointLabel = uilabel(app.RightPanel);
            app.StartPointLabel.FontWeight = 'bold';
            app.StartPointLabel.Position = [100 123 70 22];
            app.StartPointLabel.Text = 'Start Point:';

            % Create EndXLabel
            app.EndXLabel = uilabel(app.RightPanel);
            app.EndXLabel.HorizontalAlignment = 'right';
            app.EndXLabel.Position = [220 102 62 22];
            app.EndXLabel.Text = 'EndX';

            % Create EndYLabel
            app.EndYLabel = uilabel(app.RightPanel);
            app.EndYLabel.Position = [313 102 35 22];
            app.EndYLabel.Text = 'EndY';

            % Create EndPointLabel
            app.EndPointLabel = uilabel(app.RightPanel);
            app.EndPointLabel.FontWeight = 'bold';
            app.EndPointLabel.Position = [255 123 65 22];
            app.EndPointLabel.Text = 'End Point:';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = MainApp

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end