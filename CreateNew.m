classdef CreateNew < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                  matlab.ui.Figure
        ConfirmButton             matlab.ui.control.Button
        CancelButton              matlab.ui.control.Button
        EEGFilePathTextAreaLabel  matlab.ui.control.Label
        EEGInput                  matlab.ui.control.TextArea
        Browse1                   matlab.ui.control.Button
        NameNewSetEditFieldLabel  matlab.ui.control.Label
        NameNewSet                matlab.ui.control.EditField
    end


    properties (Access = private) 
        CallingApp;   % Main app object
        filelist='';
        path=''; 

        name;
    end


    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function StartupFcn(app, mainapp)
            % Store main app in property for CloseRequestFcn to use
            app.CallingApp = mainapp;
            app.name=strcat('Dataset_', num2str(app.CallingApp.CurrentNumOfDataset)); %default name
            app.NameNewSet.Value=app.name;
        end

        % Button pushed function: Browse1
        function Browse1ButtonPushed(app, event)
            [app.filelist,app.path] = uigetfile('*.set','Select One or More Files','MultiSelect','on');
            
            app.EEGInput.Value=app.path;%show selected file on UI
        end

        % Value changed function: NameNewSet
        function NameNewSetValueChanged(app, event)
            value = app.NameNewSet.Value;
            app.name=value;
            app.NameNewSet.Value=app.name;
        end

        % Button pushed function: ConfirmButton
        function ConfirmButtonPushed(app, event)
            %Change the indexes in main function
            app.CallingApp.NumOfDataSet=app.CallingApp.NumOfDataSet+1;
            app.CallingApp.DataSetList(app.CallingApp.NumOfDataSet).NameOfSet=app.NameNewSet.Value;
            app.CallingApp.DataSetList(app.CallingApp.NumOfDataSet).Input=app.path;
            app.CallingApp.DataSetList(app.CallingApp.NumOfDataSet).FileNames=app.filelist; 
            
            Prep(app.CallingApp);
            app.CallingApp.CurrentNumOfDataSet=app.CallingApp.NumOfDataSet;
            initialization(app.CallingApp);
            
            app.CallingApp.isImport=1; %
            % Delete the dialog box
            app.CallingApp.CreateNewButton.Enable = 'on';
            delete(app)
        end

        % Button pushed function: CancelButton
        function CancelButtonPushed(app, event)
             % Delete the dialog box
            app.CallingApp.CreateNewButton.Enable = 'on';
            delete(app)
        end

        % Close request function: UIFigure
        function DialogAppCloseRequest(app, event)
            % Enable the Plot Opions button in main app
            app.CallingApp.CreateNewButton.Enable = 'on';
            
            % Delete the dialog box 
            delete(app)
            
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [600 100 427 295];
            app.UIFigure.Name = 'Options';
            app.UIFigure.CloseRequestFcn = createCallbackFcn(app, @DialogAppCloseRequest, true);

            % Create ConfirmButton
            app.ConfirmButton = uibutton(app.UIFigure, 'push');
            app.ConfirmButton.ButtonPushedFcn = createCallbackFcn(app, @ConfirmButtonPushed, true);
            app.ConfirmButton.Position = [88 31 100 22];
            app.ConfirmButton.Text = 'OK';

            % Create CancelButton
            app.CancelButton = uibutton(app.UIFigure, 'push');
            app.CancelButton.ButtonPushedFcn = createCallbackFcn(app, @CancelButtonPushed, true);
            app.CancelButton.Position = [272 31 100 22];
            app.CancelButton.Text = 'Cancel';

            % Create EEGFilePathTextAreaLabel
            app.EEGFilePathTextAreaLabel = uilabel(app.UIFigure);
            app.EEGFilePathTextAreaLabel.HorizontalAlignment = 'right';
            app.EEGFilePathTextAreaLabel.Position = [27 185 81 22];
            app.EEGFilePathTextAreaLabel.Text = {'EEG File Path'; ''};

            % Create EEGInput
            app.EEGInput = uitextarea(app.UIFigure);
            app.EEGInput.HorizontalAlignment = 'center';
            app.EEGInput.Position = [134 185 140 21];

            % Create Browse1
            app.Browse1 = uibutton(app.UIFigure, 'push');
            app.Browse1.ButtonPushedFcn = createCallbackFcn(app, @Browse1ButtonPushed, true);
            app.Browse1.Position = [292 185 59 22];
            app.Browse1.Text = 'Browse';

            % Create NameNewSetEditFieldLabel
            app.NameNewSetEditFieldLabel = uilabel(app.UIFigure);
            app.NameNewSetEditFieldLabel.HorizontalAlignment = 'right';
            app.NameNewSetEditFieldLabel.Position = [12 137 96 22];
            app.NameNewSetEditFieldLabel.Text = 'Name New Set';

            % Create NameNewSet
            app.NameNewSet = uieditfield(app.UIFigure, 'text');
            app.NameNewSet.ValueChangedFcn = createCallbackFcn(app, @NameNewSetValueChanged, true);
            app.NameNewSet.Position = [134 137 140 22];

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = CreateNew(varargin)

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @(app)StartupFcn(app, varargin{:}))

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