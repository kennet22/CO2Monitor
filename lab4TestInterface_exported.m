classdef lab4TestInterface_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        CO2_Concentration_Testing   matlab.ui.Figure
        secondGraph                 matlab.ui.control.UIAxes
        ControlsPanel               matlab.ui.container.Panel
        StartButton                 matlab.ui.control.Button
        StopButton                  matlab.ui.control.Button
        ResetButton                 matlab.ui.control.Button
        SaveButton                  matlab.ui.control.Button
        TestLengthminLabel          matlab.ui.control.Label
        TestLength                  matlab.ui.control.NumericEditField
        FileNameLabel               matlab.ui.control.Label
        fileName                    matlab.ui.control.EditField
        HeatingProcessCheckBox      matlab.ui.control.CheckBox
        TestingInterfaceLabel       matlab.ui.control.Label
        ParametersPanel             matlab.ui.container.Panel
        CO2PPMEditFieldLabel        matlab.ui.control.Label
        CO2PPMValue                 matlab.ui.control.NumericEditField
        AverageCO2PPMGraphCheckBox  matlab.ui.control.CheckBox
        OutputVoltageLabel          matlab.ui.control.Label
        outputVoltage               matlab.ui.control.NumericEditField
        ADCValueLabel               matlab.ui.control.Label
        adcValue                    matlab.ui.control.NumericEditField
        CurrentTimeEditFieldLabel   matlab.ui.control.Label
        time                        matlab.ui.control.EditField
        minuteGraph                 matlab.ui.control.UIAxes
        BluetoothConnectionPanel    matlab.ui.container.Panel
        ConnectButton               matlab.ui.control.Button
        DisconnectButton            matlab.ui.control.Button
        bluetoothStatusLamp         matlab.ui.control.Lamp
    end

    
    properties (Access = private)
        b; % Bluetooth object name
        getData = 1; % Variable that controls start loop
        col = 1;
        row = 1;
        dataTable = zeros(600,4);
        CO2PPM = 0;
        seconds = 0;
        minutes = 0;
        totalTime = 0;
        s1;
        p1;
        p2;
        checkBoxValue;
        maxValue = 101;
        fn;
    end
    
    methods (Access = private)
        
        function max(app, array)
            app.maxValue = 0;
            for i = 1: size(array)
                if (app.maxValue < array(i))
                    app.maxValue = array(i);
                end
            end
        end
        
        function timer(app)
            if (app.minutes > 0)
                 if (app.seconds < 10)
                    app.time.Value = strcat(num2str(app.minutes),":0");
                    app.time.Value = strcat(app.time.Value, num2str(app.seconds));
                 else
                    app.time.Value = strcat(num2str(app.minutes),":");
                    app.time.Value = strcat(app.time.Value,num2str(app.seconds));
                end 
            else
                if (app.seconds < 10)
                    app.time.Value = strcat("0:","0");
                    app.time.Value = strcat(app.time.Value, num2str(app.seconds));
                else
                    app.time.Value = strcat("0:",num2str(app.seconds));
                end 
            end
            
            
        end
    end
    

    methods (Access = private)

        % Button pushed function: ConnectButton
        function ConnectButtonPushed(app, event)
            app.b = Bluetooth('btspp://CC50E3809EE6', 1);
            app.b.Terminator = 'E';
            fopen(app.b);
            app.bluetoothStatusLamp.Color = 'green';
        end

        % Button pushed function: DisconnectButton
        function DisconnectButtonPushed(app, event)
            fclose(app.b);
            app.bluetoothStatusLamp.Color = 'red';
        end

        % Button pushed function: StartButton
        function StartButtonPushed(app, event)
            app.getData = 1;
            
            minMaxPoint = 412;
            secMaxPoint = 412;
            
            TestLengthValueChanged(app);
            
            
            while(app.getData)
                
                % Increment time and assign current time
                pause(1);
                app.seconds = app.seconds + 1;
                app.totalTime = app.totalTime + 1;
                
                timer(app);
                
                % Send ASCII 1 to MCU and store response as data
                fwrite(app.b, 49);
                
%                 Reading in multiple inputs = [CO2PPM, OUTPUT VOLTAGE, ADC]

                % Split incoming data
                data = split(fgetl(app.b), ',');
                app.CO2PPM = str2double(data(1));
                sensorVoltage = str2double(data(2));
                ADC = str2double(data(3));  
                
                % Assign values
                app.CO2PPMValue.Value = app.CO2PPM;
                app.adcValue.Value = ADC;
                app.outputVoltage.Value = sensorVoltage;
                
                % Store data in a table
                app.dataTable(app.totalTime, 1) = app.totalTime;
                app.dataTable(app.totalTime, 2) = app.CO2PPM;
                app.dataTable(app.totalTime, 3) = sensorVoltage;
                app.dataTable(app.totalTime, 4) = ADC;
                
                % Create arrays for graphing
                minuteGraphTime(app.totalTime) = app.totalTime;
                minuteGraphData(app.totalTime) = app.CO2PPM;
               
                secondGraphTime(app.seconds) = app.seconds;
                secondGraphData(app.seconds) = app.CO2PPM;
                
                % Keep track of the max value recorded
                if (minMaxPoint < app.CO2PPM)
                    minMaxPoint = app.CO2PPM;
                end
                
                if (secMaxPoint < app.CO2PPM)
                    secMaxPoint = app.CO2PPM;
                end
                

                
                % Stop the test if the test length is reached
                if (app.totalTime == app.TestLength.Value*60 && app.HeatingProcessCheckBox.Value == 0)
                    app.StopButtonPushed;
                    
                elseif (app.HeatingProcessCheckBox.Value == 1 && app.CO2PPM < 420)
                    app.StopButtonPushed;
                end
                
                % Seconds Graph Setup and Plot %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
                limit = secMaxPoint + 20;
                app.secondGraph.YLim = [400 limit];    
                
                if(limit <= 450 && limit > 400)
                    app.secondGraph.YTickLabel = 400:5:limit;
                    app.secondGraph.YTick = 400:5:limit;
                elseif(limit <= 500 && limit > 450)
                    app.secondGraph.YTickLabel = 400:10:limit;
                    app.secondGraph.YTick = 400:10:limit;
                elseif(limit <= 600 && limit > 500)
                    app.secondGraph.YTickLabel = [400:20:limit];
                    app.secondGraph.YTick = [400:20:limit];
                elseif(limit < 1000 && limit > 600)
                    app.secondGraph.YTickLabel = [400:50:limit];
                    app.secondGraph.YTick = [400:50:limit];
                elseif(limit > 1000)
                    app.secondGraph.YTickLabel = [400:100:limit];
                    app.secondGraph.YTick = [400:100:limit];
                else 
                    app.secondGraph.YTickLabel = [300:10:limit];
                    app.secondGraph.YTick = [300:10:limit];
                    app.secondGraph.YLim = [300 limit];
                end

                % Seconds Graph Update
                hold(app.secondGraph, 'on');
                app.secondGraph.ColorOrderIndex = 3;
                app.s1 = plot(app.secondGraph, secondGraphTime,  secondGraphData,'-o');
                drawnow
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % Minute update routine
                if (app.seconds == 60)
                    
                    secMaxPoint = 412;
                    app.minutes = app.minutes + 1;
                    app.seconds = 0;
                    
                    clear secondGraphTime secondGraphData;
                    hold(app.minuteGraph, 'off');
                    hold(app.secondGraph, 'off');
                    
                    % Reset graphs
                    app.secondGraph.cla;
                    app.minuteGraph.cla;
                    
                    app.minuteGraph.XGrid = 'on';
                    app.minuteGraph.YGrid = 'on';
                    
                    app.secondGraph.XGrid = 'on';
                    app.secondGraph.YGrid = 'on';
                    
                    % Setup minute graph
                    app.minuteGraph.ColorOrderIndex = 7;      
                        
                    limit = minMaxPoint + 20;
                    app.minuteGraph.YLim = [400 floor(limit)];
   
                    if(limit <= 500 && limit > 400)
                        app.minuteGraph.YTick = 400:10:limit;
                        app.minuteGraph.YTickLabel = 400:10:limit;
                    elseif(limit <= 600 && limit > 500)
                        app.minuteGraph.YTick = 400:20:limit;
                        app.minuteGraph.YTickLabel = 400:20:limit;
                    elseif(limit < 1000 && limit > 600)
                        app.minuteGraph.YTick = 400:50:limit;
                        app.minuteGraph.YTickLabel = 400:50:limit;
                    elseif(limit > 1000 && limit <= 1500)
                        app.minuteGraph.YTick = 400:100:limit;
                        app.minuteGraph.YTickLabel = 400:100:limit;
                    elseif(limit > 1500)
                        app.minuteGraph.YTick = 400:400:limit;
                        app.minuteGraph.YTickLabel = 400:400:limit;
                    else
                        app.minuteGraph.YTick = 300:10:limit;
                        app.minuteGraph.YTickLabel = 300:10:limit;
                        app.minuteGraph.YLim = [300 limit];
                    end
                    
                    plot(app.minuteGraph, minuteGraphTime, minuteGraphData ,'-');
                    drawnow
                    
                    hold(app.minuteGraph, 'on');
                    
                    % If average CO2 check box is checked, plot the ambient CO2
                    if (app.AverageCO2PPMGraphCheckBox.Value == 1)
                        
                        s = 1:412;
                        for i = 1:412
                            d(i) = 412;
                        end
                        
                        m = 1:app.TestLength.Value;
                        for i = 1:app.TestLength.Value
                            d2(i) = 412;
                        end
                        
                        % Keep graphs on plot
                        hold(app.secondGraph, 'on');
                        
                        % Add CO2 average plots
                        app.p1 = plot(app.secondGraph, s, d, '-');
                        app.p2 = plot(app.minuteGraph, m, d2, '-');
                        
                    end
                end
                
            end
        end

        % Button pushed function: StopButton
        function StopButtonPushed(app, event)
            app.getData = 0;
        
        end

        % Button pushed function: ResetButton
        function ResetButtonPushed(app, event)
    app.getData = 0;
    app.secondGraph.cla;
    app.minuteGraph.cla;
    app.CO2PPM = 0;
    app.CO2PPMValue.Value = 0;
    app.seconds = 0;
    app.minutes = 0;
    app.dataTable(:,1) = 0;
    app.dataTable(:,2) = 0;
    app.totalTime = 0;
    app.checkBoxValue = 0;
    app.AverageCO2PPMGraphCheckBoxValueChanged;
    app.outputVoltage.Value = 0;
    app.adcValue.Value = 0;
    
    timer(app);
    
    % Reset graph axis
    app.secondGraph.cla;
    app.minuteGraph.cla;
    
    % Seconds graph
    app.secondGraph.YLim = [400 500];
    app.secondGraph.YTickLabel = 400:10:500;
    app.secondGraph.YTick = 400:10:500;
    app.secondGraph.XGrid = 'on';
    app.secondGraph.YGrid = 'on';
    
    % Minute graph
    app.minuteGraph.YLim = [400 1000];
    app.minuteGraph.YTick = 400:100:1000;
    app.minuteGraph.YTickLabel = 400:100:1000;
    app.minuteGraph.XGrid = 'on';
    app.minuteGraph.YGrid = 'on';
    
        end

        % Button pushed function: SaveButton
        function SaveButtonPushed(app, event)
            T = table(app.dataTable(:,1), app.dataTable(:,2),app.dataTable(:,3), app.dataTable(:,4), 'VariableNames', {'Time','PPM','Voltage', 'ADC'});
            app.fn = strcat(strcat('labTesting/', app.fileName.Value), '.txt');
            writetable(T, app.fn);
            %dataFile = fullfile('/Desktop/labTesting/'+ app.fn, app.fn);
            %save( dataFile, '');
            
            
            % %
            % %     get the directory of your input files:
            % %     pathname = fileparts('/input/file');
            % %     use that when you save
            % %     matfile = fullfile(pathname, 'output.mat');
            % %     figfile = fullfile(pathname, 'output.fig');
            % %     save(matfile, ...');
            % %     saveas(figfile, ...');
        end

        % Value changed function: TestLength
        function TestLengthValueChanged(app, event)
            value = app.TestLength.Value*60;
            
            app.minuteGraph.XLim = [0 value];
            app.minuteGraph.XTick = 0:60:value;
            
        end

        % Value changed function: AverageCO2PPMGraphCheckBox
        function AverageCO2PPMGraphCheckBoxValueChanged(app, event)
    app.checkBoxValue = app.AverageCO2PPMGraphCheckBox.Value;
    
    s = 1:412;
    for i = 1:412
        d(i) = 412;
    end
    
    m = 1:app.TestLength.Value;
    for i = 1:app.TestLength.Value
        d2(i) = 412;
    end
    
    if (app.checkBoxValue == 1)
        app.p1 = plot(app.secondGraph, s, d, '-');
        app.p2 = plot(app.minuteGraph, m, d2, '-');
    else
        delete(app.p1);
        delete(app.p2);
    end
        end

        % Value changed function: HeatingProcessCheckBox
        function HeatingProcessCheckBoxValueChanged(app, event)
    value = app.HeatingProcessCheckBox.Value;
    
        end
    end

    % App initialization and construction
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create CO2_Concentration_Testing
            app.CO2_Concentration_Testing = uifigure;
            app.CO2_Concentration_Testing.Position = [100 100 614 547];
            app.CO2_Concentration_Testing.Name = 'UI Figure';
            app.CO2_Concentration_Testing.Resize = 'off';

            % Create secondGraph
            app.secondGraph = uiaxes(app.CO2_Concentration_Testing);
            title(app.secondGraph, '')
            xlabel(app.secondGraph, 'Time (sec)')
            ylabel(app.secondGraph, {'CO2 (PPM)'; ''})
            app.secondGraph.PlotBoxAspectRatio = [1 0.735191637630662 0.735191637630662];
            app.secondGraph.XLim = [0 60];
            app.secondGraph.YLim = [400 500];
            app.secondGraph.ZLim = [0 2000];
            app.secondGraph.XTick = [0 10 20 30 40 50 60];
            app.secondGraph.XTickLabel = {'0'; '10'; '20'; '30'; '40'; '50'; '60'};
            app.secondGraph.YTick = [400 410 420 430 440 450 460 470 480 490 500];
            app.secondGraph.YTickLabel = {'400'; '410'; '420'; '430'; '440'; '450'; '460'; '470'; '480'; '490'; '500'};
            app.secondGraph.NextPlot = 'add';
            app.secondGraph.XGrid = 'on';
            app.secondGraph.YGrid = 'on';
            app.secondGraph.Position = [237 275 360 254];

            % Create ControlsPanel
            app.ControlsPanel = uipanel(app.CO2_Concentration_Testing);
            app.ControlsPanel.Title = 'Controls';
            app.ControlsPanel.FontWeight = 'bold';
            app.ControlsPanel.Position = [19 306 193 193];

            % Create StartButton
            app.StartButton = uibutton(app.ControlsPanel, 'push');
            app.StartButton.ButtonPushedFcn = createCallbackFcn(app, @StartButtonPushed, true);
            app.StartButton.Position = [17 142 68 22];
            app.StartButton.Text = 'Start';

            % Create StopButton
            app.StopButton = uibutton(app.ControlsPanel, 'push');
            app.StopButton.ButtonPushedFcn = createCallbackFcn(app, @StopButtonPushed, true);
            app.StopButton.Position = [105 142 68 22];
            app.StopButton.Text = 'Stop';

            % Create ResetButton
            app.ResetButton = uibutton(app.ControlsPanel, 'push');
            app.ResetButton.ButtonPushedFcn = createCallbackFcn(app, @ResetButtonPushed, true);
            app.ResetButton.Position = [17 106 68 22];
            app.ResetButton.Text = 'Reset';

            % Create SaveButton
            app.SaveButton = uibutton(app.ControlsPanel, 'push');
            app.SaveButton.ButtonPushedFcn = createCallbackFcn(app, @SaveButtonPushed, true);
            app.SaveButton.Position = [105 106 68 22];
            app.SaveButton.Text = 'Save';

            % Create TestLengthminLabel
            app.TestLengthminLabel = uilabel(app.ControlsPanel);
            app.TestLengthminLabel.HorizontalAlignment = 'right';
            app.TestLengthminLabel.Position = [-12 41 117 22];
            app.TestLengthminLabel.Text = 'Test Length (min)';

            % Create TestLength
            app.TestLength = uieditfield(app.ControlsPanel, 'numeric');
            app.TestLength.Limits = [0 1200];
            app.TestLength.ValueChangedFcn = createCallbackFcn(app, @TestLengthValueChanged, true);
            app.TestLength.Position = [116 41 51 22];
            app.TestLength.Value = 20;

            % Create FileNameLabel
            app.FileNameLabel = uilabel(app.ControlsPanel);
            app.FileNameLabel.HorizontalAlignment = 'right';
            app.FileNameLabel.Position = [4 74 68 22];
            app.FileNameLabel.Text = 'File Name:';

            % Create fileName
            app.fileName = uieditfield(app.ControlsPanel, 'text');
            app.fileName.Position = [89 74 93 22];
            app.fileName.Value = 'test';

            % Create HeatingProcessCheckBox
            app.HeatingProcessCheckBox = uicheckbox(app.ControlsPanel);
            app.HeatingProcessCheckBox.ValueChangedFcn = createCallbackFcn(app, @HeatingProcessCheckBoxValueChanged, true);
            app.HeatingProcessCheckBox.Text = 'Heating Process';
            app.HeatingProcessCheckBox.Position = [15 6 110 22];

            % Create TestingInterfaceLabel
            app.TestingInterfaceLabel = uilabel(app.CO2_Concentration_Testing);
            app.TestingInterfaceLabel.FontSize = 18;
            app.TestingInterfaceLabel.FontWeight = 'bold';
            app.TestingInterfaceLabel.Position = [44 504 149 25];
            app.TestingInterfaceLabel.Text = 'Testing Interface';

            % Create ParametersPanel
            app.ParametersPanel = uipanel(app.CO2_Concentration_Testing);
            app.ParametersPanel.Title = 'Parameters';
            app.ParametersPanel.FontWeight = 'bold';
            app.ParametersPanel.Position = [19 120 193 172];

            % Create CO2PPMEditFieldLabel
            app.CO2PPMEditFieldLabel = uilabel(app.ParametersPanel);
            app.CO2PPMEditFieldLabel.HorizontalAlignment = 'right';
            app.CO2PPMEditFieldLabel.Position = [4 87 66 22];
            app.CO2PPMEditFieldLabel.Text = 'CO2 (PPM)';

            % Create CO2PPMValue
            app.CO2PPMValue = uieditfield(app.ParametersPanel, 'numeric');
            app.CO2PPMValue.Position = [119 86 54 22];

            % Create AverageCO2PPMGraphCheckBox
            app.AverageCO2PPMGraphCheckBox = uicheckbox(app.ParametersPanel);
            app.AverageCO2PPMGraphCheckBox.ValueChangedFcn = createCallbackFcn(app, @AverageCO2PPMGraphCheckBoxValueChanged, true);
            app.AverageCO2PPMGraphCheckBox.Text = 'Avergae CO2 PPM Graph';
            app.AverageCO2PPMGraphCheckBox.Position = [15 1 159 22];

            % Create OutputVoltageLabel
            app.OutputVoltageLabel = uilabel(app.ParametersPanel);
            app.OutputVoltageLabel.HorizontalAlignment = 'right';
            app.OutputVoltageLabel.Position = [4 58 86 22];
            app.OutputVoltageLabel.Text = 'Output Voltage';

            % Create outputVoltage
            app.outputVoltage = uieditfield(app.ParametersPanel, 'numeric');
            app.outputVoltage.Position = [119 57 54 22];

            % Create ADCValueLabel
            app.ADCValueLabel = uilabel(app.ParametersPanel);
            app.ADCValueLabel.HorizontalAlignment = 'right';
            app.ADCValueLabel.Position = [4 29 63 22];
            app.ADCValueLabel.Text = 'ADC Value';

            % Create adcValue
            app.adcValue = uieditfield(app.ParametersPanel, 'numeric');
            app.adcValue.Position = [119 29 55 22];

            % Create CurrentTimeEditFieldLabel
            app.CurrentTimeEditFieldLabel = uilabel(app.ParametersPanel);
            app.CurrentTimeEditFieldLabel.HorizontalAlignment = 'center';
            app.CurrentTimeEditFieldLabel.Position = [4 117 81 22];
            app.CurrentTimeEditFieldLabel.Text = 'Current Time';

            % Create time
            app.time = uieditfield(app.ParametersPanel, 'text');
            app.time.HorizontalAlignment = 'right';
            app.time.Position = [118 117 55 22];
            app.time.Value = '0:00';

            % Create minuteGraph
            app.minuteGraph = uiaxes(app.CO2_Concentration_Testing);
            title(app.minuteGraph, '')
            xlabel(app.minuteGraph, 'Time (min)')
            ylabel(app.minuteGraph, 'CO2 (PPM)')
            app.minuteGraph.PlotBoxAspectRatio = [1 0.698245614035088 0.698245614035088];
            app.minuteGraph.XLim = [0 20];
            app.minuteGraph.YLim = [400 2000];
            app.minuteGraph.ZLim = [0 2000];
            app.minuteGraph.XTick = [0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20];
            app.minuteGraph.XTickLabel = {'0'; '1'; '2'; '3'; '4'; '5'; '6'; '7'; '8'; '9'; '10'; '11'; '12'; '13'; '14'; '15'; '16'; '17'; '18'; '19'; '20'};
            app.minuteGraph.YTick = [400 500 600 700 800 900 1000 1100 1200 1300 1400 1500 1600 1700 1800 1900 2000];
            app.minuteGraph.YTickLabel = {'400'; '500'; '600'; '700'; '800'; '900'; '1000'; '1100'; '1200'; '1300'; '1400'; '1500'; '1600'; '1700'; '1800'; '1900'; '2000'};
            app.minuteGraph.NextPlot = 'add';
            app.minuteGraph.XGrid = 'on';
            app.minuteGraph.YGrid = 'on';
            app.minuteGraph.Position = [237 14 360 254];

            % Create BluetoothConnectionPanel
            app.BluetoothConnectionPanel = uipanel(app.CO2_Concentration_Testing);
            app.BluetoothConnectionPanel.Title = 'Bluetooth Connection';
            app.BluetoothConnectionPanel.FontWeight = 'bold';
            app.BluetoothConnectionPanel.Position = [19 14 193 93];

            % Create ConnectButton
            app.ConnectButton = uibutton(app.BluetoothConnectionPanel, 'push');
            app.ConnectButton.ButtonPushedFcn = createCallbackFcn(app, @ConnectButtonPushed, true);
            app.ConnectButton.Position = [55 42 68 22];
            app.ConnectButton.Text = 'Connect';

            % Create DisconnectButton
            app.DisconnectButton = uibutton(app.BluetoothConnectionPanel, 'push');
            app.DisconnectButton.ButtonPushedFcn = createCallbackFcn(app, @DisconnectButtonPushed, true);
            app.DisconnectButton.Position = [51 9 76 22];
            app.DisconnectButton.Text = 'Disconnect';

            % Create bluetoothStatusLamp
            app.bluetoothStatusLamp = uilamp(app.BluetoothConnectionPanel);
            app.bluetoothStatusLamp.Position = [24 43 20 20];
            app.bluetoothStatusLamp.Color = [1 0 0];
        end
    end

    methods (Access = public)

        % Construct app
        function app = lab4TestInterface_exported

            % Create and configure components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.CO2_Concentration_Testing)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.CO2_Concentration_Testing)
        end
    end
end