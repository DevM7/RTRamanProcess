%% Click Run to start, don't manipulate this section
close all force
close all hidden
RTRamanProcess;
%% Contorl Ocean Optics QE PRO and Real-Time Process Raman Spectrum 
function RTRamanProcess()
%% Variables Initilization
CurrentDirectory = pwd; 
% Current Background spectrum and raw spectrum
BGSpec = []; 
RawSpec = []; 
% Component Matrix for regression 
Component = [];
% Selected Component matrix for regression 
ComponentRegression = [];
% Selected background File and spectrum file
BGFileSelected = [];
SpectrumFileSelected  = [];
%% Initilize app
for Initialization = 1
        for Environment = 1
           % Check if exist directory 
           BGTableDirectory = [CurrentDirectory '/Background'];
           AnaTableDirectory = [CurrentDirectory '/Saved Spectrum']; 
           % Create default folders for data I/O
           if exist(BGTableDirectory,'dir') ~= 7
               mkdir(BGTableDirectory);
           end
           if exist(AnaTableDirectory,'dir') ~= 7
               mkdir(AnaTableDirectory);
           end
        end
        for MainWindow = 1
        % Initialize main window
        Main = uifigure('Name','Quick Raman Process');
        Main.Position = [0 0 1000 900];
        Main.Resize = 'off';
        Main.CloseRequestFcn = @(Main,event)CloseRequestFcn(Main);
        Main.KeyPressFcn = @(Main,event)SpaceSaveSpectrumFcn(event);
        movegui(Main,'center');
        end
        for Displays = 1
        % Raw Spectrum
        Raw = uiaxes(Main);
        Raw.Position = [50 620 900 280];
        Raw.Title.String = 'Raw Spectrum';
        Raw.XLabel.String = 'Wavelength(nm)';
        Raw.YLabel.String = 'A.U';
        Raw.XLim = [780 1150];
        Raw.YLim = [-inf inf];
        Raw.Toolbar.Visible = 'off';
        Raw.XGrid = 'on';
        Raw.YGrid = 'on';
        set(Raw,'DefaultLineLineWidth',1.5);
        Colormat = get(Raw,'colororder');
        %disableDefaultInteractivity(Raw);
        
        % % Fingerprint Spectrum
        Fingerprint = uiaxes(Main);
        Fingerprint.Position = [50 315 450 300];
        Fingerprint.Title.String = 'Fingerprint Normalized';
        Fingerprint.XLabel.String = 'Raman Shift (cm^-1)';
        Fingerprint.YLabel.String = 'A.U';
        Fingerprint.XLim = [795 1805];
        Fingerprint.YLim = [0 inf];
        Fingerprint.Toolbar.Visible = 'off';
        Fingerprint.XGrid = 'on';
        Fingerprint.YGrid = 'on';
        set(Fingerprint,'DefaultLineLineWidth',1.5);
        %disableDefaultInteractivity(Fingerprint);
        
        % Regressional Rsquare value 
        Rsquare =  uieditfield(Main,'numeric','Position',[440 595 48 20]);
        Rsquare.Enable = 'off';
        uilabel(Main,'Position',[410 595 60 20],'Text','R^2:');    
        
        % Highwave spectrum
        Highwave = uiaxes(Main);
        Highwave.Position = [500 315 450 300];
        Highwave.Title.String = 'Highwave Normalized';
        Highwave.XLabel.String = 'Raman Shift (cm^-1)';
        Highwave.YLabel.String = 'A.U';
        Highwave.XLim = [2595 3805];
        Highwave.YLim = [0 inf];
        Highwave.Toolbar.Visible = 'off';
        Highwave.XGrid = 'on';
        Highwave.YGrid = 'on';
        set(Highwave,'DefaultLineLineWidth',1.5);
        disableDefaultInteractivity(Highwave);
        end
        for ControlPanel = 1
        % Input buttom groups
        Control = uibuttongroup(Main,'Position',[50 20 450 290]);
        % Select Directory
        SelectDirectory = uibutton(Control,'push');
        SelectDirectory.Position = [11 260 150 22];
        SelectDirectory.Text = 'Select Directory';
        SelectDirectory.ButtonPushedFcn = @(Directory,event)SelectDirectoryFcn();
        DirectoryLabel = uilabel(Control);
        DirectoryLabel.Position = [170 260 300 22];
        DirectoryLabel.Text = CurrentDirectory;
        
        % Obtain background
        ObtainBackground = uibutton(Control,'push');
        ObtainBackground.Position = [11 230 150 22];
        ObtainBackground.Text = 'Obtain Background';
        ObtainBackground.ButtonPushedFcn = @(BG,event)ObtainBackgroundFcn();
        
        % Continuous Acquisition
        ContinuousAcquisition = uibutton(Control,'state');
        ContinuousAcquisition.Position = [11 200 150 22];
        ContinuousAcquisition.Text = 'Continuous Acquisition';
        ContinuousAcquisition.ValueChangedFcn = @(ContinuousAcquisition,event)ContinuousAcquisitionFcn();
        
        % Save Spectrum
        SaveSpectrum = uibutton(Control,'push');
        SaveSpectrum.Position = [11 170 150 22];
        SaveSpectrum.Text = 'Save Spectrum';
        SaveSpectrum.Enable = 'off';
        SaveSpectrum.ButtonPushedFcn = @(SaveSpectrum,event)SaveSpectrumFcn();
        
        % Terminate/restart App
        TerminateRestart = uibutton(Control,'push');
        TerminateRestart.Position = [11 140 150 22];
        TerminateRestart.Text = 'Terminate and Restart';
        TerminateRestart.ButtonPushedFcn = @(Terminate,event)TerminateRestartFcn();
        
        % Integration time
        IntegrationTime = uieditfield(Control,'numeric');
        IntegrationTime.Position = [120 110 40 22];
        IntegrationTime.Value = 3; % seconds
        IntegrationTime.Limits = [0,300];
        IntegrationTime.Editable = 'on';
        uilabel(Control,'Position',[11 110 140 22],'Text','Integration Time (s)');
        
        % Scan to average
        Scan2Average = uieditfield(Control,'numeric');
        Scan2Average.Position = [120 85 40 22];
        Scan2Average.Value = 1; % # of spectrum to average
        Scan2Average.Limits = [0,10];
        Scan2Average.Editable = 'on';
        uilabel(Control,'Position',[11 85 140 22],'Text','Scan to Average');
        
        % Background subtraction
        BGSubtraction = uicheckbox(Control);
        BGSubtraction.Position = [170 230 140 22];
        BGSubtraction.Text = 'BG Subtraction';
        BGSubtraction.Enable = 'off';
        
        % Electrical Dark
        ContinuousSave = uicheckbox(Control);
        ContinuousSave.Position = [305 230 140 22];
        ContinuousSave.Text = 'Continuous Save';
        ContinuousSave.Value = 0;
        
        % Sav.Golay Filter Width
        SavFilter = uieditfield(Control,'numeric');
        SavFilter.Position = [120 60 40 22];
        SavFilter.Value = 3;
        SavFilter.Limits = [1,15];
        SavFilter.Editable = 'on';
        SavFilter.ValueChangedFcn = @(SavFilter,event) CheckSavGolWidthFcn();
        uilabel(Control,'Position',[11 60 140 22],'Text','Sav-Golay Width');
        
        % Fingerprint Baseline subtraction
        FPBaseline = uieditfield(Control,'numeric');
        FPBaseline.Position = [120 35 40 22];
        FPBaseline.Value = 5;
        FPBaseline.Limits = [1,15];
        FPBaseline.Editable = 'on';
        uilabel(Control,'Position',[11 35 140 22],'Text','Fingerprint Baseline');
        
        % Highwave basedline subtraction
        HWBaseline = uieditfield(Control,'numeric');
        HWBaseline.Position = [120 10 40 22];
        HWBaseline.Value = 1;
        HWBaseline.Limits = [1,3];
        HWBaseline.Editable = 'on';
        uilabel(Control,'Position',[11 10 140 22],'Text','Highwave Baseline');
        
        % Regression selection
        RTRegression = uicheckbox(Control);
        RTRegression.Text = 'RealTime Regression';
        RTRegression.Position = [170 200 140 22];
        RTRegression.Enable = 'off';
        RTRegression.ValueChangedFcn = @(RTRegression,event) RTRegFcn();
        
        % Regression load component
        ImportComponent = uibutton(Control,'push');
        ImportComponent.Position = [170 170 270 22];
        ImportComponent.Text = 'Load Regression Components';
        ImportComponent.ButtonPushedFcn = @(Import,event)ImportComponentFcn();
        
        % Regression select Component
        ComponentTable = uitable(Control);
        ComponentTable.Position = [170 10 270 150];
        ComponentTable.RowName = [];
        ComponentTable.ColumnName = {[],'Name','Score'};
        ComponentTable.ColumnFormat = {'logical','char','numeric'};
        ComponentTable.ColumnEditable = [true,false];
        ComponentTable.ColumnWidth = {20,'auto','auto'};
        ComponentTable.CellEditCallback = @(ComponentTable,event)SelectComponentFcn();
        
        % Composition selection
        RTComposition = uicheckbox(Control);
        RTComposition.Position = [305 200 140 22];
        RTComposition.Text = 'RealTime Composition';
        RTComposition.Enable = 'off';
        RTComposition.ValueChangedFcn = @(RTRegression,event) RTComFcn();
        
        % Delete Background Selection
        DeleteBG = uibutton(Main,'push');
        DeleteBG.Position = [510 285 115 22];
        DeleteBG.Text = 'Delete Background';
        DeleteBG.Enable = 'off';
        DeleteBG.ButtonPushedFcn = @(DeleteBG,event)DeleteBGFcn();
        
        % Delete Result Selection
        DeleteSpectrum = uibutton(Main,'push');
        DeleteSpectrum.Position = [630 285 110 22];
        DeleteSpectrum.Text = 'Delete Spectrum';
        DeleteSpectrum.Enable = 'off';
        DeleteSpectrum.ButtonPushedFcn = @(DeleteSpectrum,event)DeleteSpectrumFcn();
        
        % Export Result Selection
        ExportResult = uibutton(Main,'push');
        ExportResult.Position = [745 285 110 22];
        ExportResult.Text = 'Export Result';
        ExportResult.Enable = 'off';
        ExportResult.ButtonPushedFcn = @(ExportResult,event)ExportResultFcn();
        
        % Process Mode
        ProcessMode = uibutton(Main,'state');
        ProcessMode.Position = [860 285 110 22];
        ProcessMode.Text = 'Processing Mode';
        ProcessMode.ValueChangedFcn = @(ProcessRaw,event)ProcessModeFcn();

        % PID 
        PatientID = uieditfield(Main);
        PatientID.Position = [575 153 55 22];
        PatientID.Value = '000000';
        PatientID.Editable = 'on';
        uilabel(Main,'Position',[510 153 70 22],'Text','Patient ID#');
        
        % Session 
        SessionNum = uieditfield(Main);
        SessionNum.Position = [690 153 55 22];
        SessionNum.Value = '000000';
        SessionNum.Editable = 'on';
        uilabel(Main,'Position',[635 153 70 22],'Text','Session#');
        
        % SessionName
        SessionName = uieditfield(Main);
        SessionName.Position = [830 153 65 22];
        SessionName.Value = 'default';
        SessionName.Editable = 'on';
        uilabel(Main,'Position',[750 153 80 22],'Text','Session Name');
        
        % Reset
        ResetPatient = uibutton(Main,'push');
        ResetPatient.Position = [900 153 70 22];
        ResetPatient.Text = 'Reset';
        ResetPatient.ButtonPushedFcn = @(Terminate,event)ResetPatientFcn();
        end
        for BackgroundTable = 1
        % Background Table
        BGTable = uitable(Main);
            BGTable.Position = [510 180 460 100];
            BGTable.RowName = 'numbered';
            BGTable.ColumnName = {[],'Datetime','Time','Scan2Ave','Name'};
            BGTable.ColumnFormat = {'logical','char','numeric','numeric','char'};
            BGTable.ColumnEditable = [true,false,false,false,true];
            BGTable.ColumnWidth = {20,125,43,75,'auto'};
            BGTable.CellEditCallback = @(BGTable,event) SelectBGFcn(event);
            BGTable.CellSelectionCallback = @(BGTable,event) ChooseBGDeleteFcn(event);
            ReadFolder(BGTable,BGTableDirectory);
        end
        for ResultTable =1  
        % Result Table
        AnaTable = uitable(Main);
            AnaTable.Position = [510 20 460 130];
            AnaTable.RowName = 'numbered';
            AnaTable.ColumnName = {[],'Datetime','Time','Scan2Ave','Name'};
            AnaTable.ColumnFormat = {'logical','char','numeric','numeric','char'};
            AnaTable.ColumnEditable = [true,false,false,false,true];
            AnaTable.ColumnWidth = {20,125,43,75,'auto'};
            AnaTable.CellEditCallback = @(AnaTable,event) SelectSpectrumFcn(event);
            AnaTable.CellSelectionCallback = @(AnaTable,event) ChooseSpectrumDeleteFcn(event);
            ReadFolder(AnaTable,AnaTableDirectory);
        end
        for SpectralCalibration = 1
        pixel = 1:1044;
        % Calibration curve
        first_coeff = 0.3775735199;
        second_coeff = -2.53963 * 10^(-5);
        intercept = 782.38751221;
        Wavelength = first_coeff.*(pixel) + second_coeff.*(pixel.^2) + intercept;
        excitation_wavelength = 785; %Incident light wavelength
        RamanWavenumber = 10^7 * (1/excitation_wavelength - 1./Wavelength)'; % calculate raman shift
        FPStart = 148; FPEnd = 358; %800-1800 cm-1
        HWStart = 561; HWEnd = 1030; %2600-4000 cm-1
        end
        for Spectrometer = 1
          javaaddpath('C:\Program Files\Ocean Optics\OmniDriver\OOI_HOME\OmniDriver.jar')
          import('java.lang.Object');
          import('com.oceanoptics.omnidriver.api.wrapper.Wrapper');
          wrapper = Wrapper();
          wrapper.openAllSpectrometers();
          wrapper.setCorrectForElectricalDark(0,1)
        end
        disp('Initilization Complete!');
end 
%% Supplement Functions
    % Functions listed in alphabetic order
    function CheckSavGolWidthFcn()
        if ~rem(SavFilter.Value,2)
           SavFilter.Value = SavFilter.Value-1;
        end
    end 
    function ChooseBGDeleteFcn(event)
        if ProcessMode.Value == 0 % Not useable in process mode
            if size(event.Indices,1) == 5 && cell2mat(BGTable.Data(event.Indices(1,1),1)) ~= 1 % The whioke row is selected by clicking the row number
                DeleteBG.Enable = 'on';
                BGFileSelected = char(BGTable.Data(event.Indices(1,1),5));
            else
                DeleteBG.Enable = 'off';
                BGFileSelected = [];
            end
        end
    end
    function ChooseSpectrumDeleteFcn(event)
        if ProcessMode.Value == 0 % not usable in process mode
            if size(event.Indices,1) == 5 % if the whole row is selected
                if cell2mat(AnaTable.Data(event.Indices(1,1),event.Indices(1,2))) == 1 % if the current spectrum is checked (plotted), not able to delete
                    DeleteSpectrum.Enable = 'off';
                    SpectrumFileSelected = [];
                else
                    DeleteSpectrum.Enable = 'on';
                    SpectrumFileSelected = char(AnaTable.Data(event.Indices(1,1),5));
                end
            else 
                DeleteSpectrum.Enable = 'off';
                SpectrumFileSelected = [];
            end
        end
    end
    function CloseRequestFcn(Main,~)
        % To close the window
        selection = uiconfirm(Main,'Close the figure window?','Confirmation');
        switch selection
            case 'OK'
                wrapper.closeAllSpectrometers();
                delete(Main)
            case 'Cancel'
                return
        end
    end
    function ContinuousAcquisitionFcn() 
        if ContinuousAcquisition.Value == 1 %Continuous acquisition on 
            % Interface appearance adjustment
            ContinuousAcquisition.Text = 'Acquiring';
            ContinuousAcquisition.BackgroundColor = 'g';
            ObtainBackground.Enable = 'off';
            ImportComponent.Enable = 'off';
            DeleteSpectrum.Enable = 'off';
            DeleteBG.Enable = 'off';
            ProcessMode.Enable = 'off';
            IntegrationTime.Enable = 'off';
            Scan2Average.Enable = 'off';
            % Change the default acquisition time, wait till next available
            % spectrum 
            wrapper.setIntegrationTime(0, 1000000 * IntegrationTime.Value);
            wrapper.setScansToAverage(0, Scan2Average.Value);
            RawSpec = [];
            pause(IntegrationTime.Value)
            for i = 1:100000
                if ContinuousAcquisition.Value == 0
                    break;
                else
                    % obtain the spectrum, plot and preprocess
                    RawSpec = wrapper.getSpectrum(0);
                    if ContinuousSave.Value == 1 % when Continuous save is on
                        SaveSpectrum.Enable = 'off';
                        SaveSpectrumFcn();
                    else
                        SaveSpectrum.Enable = 'on';
                    end
                    plot(Raw,Wavelength,RawSpec);
                    drawnow
                    Preprocess(RawSpec,BGSpec,'one');
                end
            end  
        else % stop continuous Acquisition 
            % Appearance adjustment
            ContinuousAcquisition.Text = 'Continuous Acquisition';
            ContinuousAcquisition.BackgroundColor = [0.9600 0.9600 0.9600];
            ImportComponent.Enable = 'on';
            ProcessMode.Enable = 'on';
            SaveSpectrum.Enable = 'off';
            IntegrationTime.Enable = 'on';
            Scan2Average.Enable = 'on';
            if isempty(BGSpec) % Check if there is any background spectrum available 
               ObtainBackground.Enable = 'on'; 
            end
            RawSpec = [];
            % clear plots
            delete(Raw.Children);
            delete(Fingerprint.Children);
            delete(Highwave.Children);
            if isempty(ComponentTable.Data) == 0 %if there is regression component, zero the scores
                ComponentTable.Data(:,3) = num2cell(zeros(size(ComponentTable.Data(:,3))));
            end
            Rsquare.Value = 0;
            % Change the integration time to a default (short) time
            wrapper.setIntegrationTime(0, 1000000 * 0.05);
            wrapper.setScansToAverage(0, Scan2Average.Value);
        end    
    end
    function Spectra_Processed =  Correct_fit(Spectra_smoothed,Polynom_order)
        % function for baseline subtraction, used in export and proprocess
        % function.
        A = Spectra_smoothed;
        [~,C] = size(A); %data smoothed, L --- column of the smoothed data
        AA = A; % AA --- data smoothed
        BB = AA; %% BB --- data smoothed
        k = 45;  %can be changed to reduce negative fit %%% in order to start the loop
        while k > 24  %can be changed to reduce negative fit
            [P,~] = polyfit(1:C,BB,Polynom_order); % data_smoothed
            Y = polyval(P,1:C);
            k = 0;
            for j = 1:C
                if Y(j) > AA(j)
                    k = k+1;
                    Y(j) = AA(j);
                end
            end
            BB = Y; %% Spectra without the negative fit and the over-valued
        end
        Spectra_Processed = (AA - BB)';
    end
    function DeleteBGFcn()
        % delete a background spectrum from BGTable when the delete button
        % is pushed
        if isempty(BGFileSelected) == 0
            delete(fullfile(BGTableDirectory,BGFileSelected));
            ReadFolder(BGTable,BGTableDirectory);
            DeleteBG.Enable = 'off';
            BGFileSelected = [];
        end
    end
    function DeleteSpectrumFcn()
        % delete a spectrum from BGTable when the delete button
        % is pushed
        if isempty(SpectrumFileSelected) == 0
            delete(fullfile(AnaTableDirectory,SpectrumFileSelected));
            ReadFolder(AnaTable,AnaTableDirectory);
            DeleteSpectrum.Enable = 'off';
            SpectrumFileSelected = [];
        end        
    end
    function ExportResultFcn()
        % Export the results in process mode
        if sum(cell2mat(BGTable.Data(:,1))) == 0 && sum(cell2mat(AnaTable.Data(:,1))) == 0 % when no spectrum is selected in both BGTable and Anatable
            disp('Please Select Data to Output!');
            return;
        else
            % Obtain output directory
            CurrentTime = char(datetime);
            CurrentTime = strrep(CurrentTime,':', '-');
            Filename = [CurrentTime '.xlsx'];
            [Filename,Path] = uiputfile(Filename);
            disp('Exporting...');
            if sum(cell2mat(BGTable.Data(:,1))) ~= 0 % Output BG table
                SelectedFiles = BGTable.Data(cell2mat(BGTable.Data(:,1)),5);
                for i = 1:size(SelectedFiles,1)
                    OneFile = importdata(fullfile(BGTableDirectory,char(SelectedFiles(i,1))));
                    BGs(:,i) = OneFile.Spectrum;
                end
                writecell(SelectedFiles',[Path Filename],'sheet','Background Spectra','range','B1');
                writematrix(BGs,[Path Filename],'sheet','Background Spectra','range','B2');
                writecell({'Raman Scale'},[Path Filename],'sheet','Background Spectra','range','A1');
                writematrix(RamanWavenumber,[Path Filename],'sheet','Background Spectra','range','A2')
            end
            if sum(cell2mat(AnaTable.Data(:,1))) ~= 0 % Output Ana Table
                % Add Raman Scale
                writecell({'Raman Scale'},[Path Filename],'sheet','Raw Spectra','range','A1');
                writematrix(RamanWavenumber,[Path Filename],'sheet','Raw Spectra','range','A2');
                writecell({'Raman Scale'},[Path Filename],'sheet','Processed Fingerprint Spectra','range','A1');
                writematrix(RamanWavenumber(FPStart:FPEnd),[Path Filename],'sheet','Processed Fingerprint Spectra','range','A2');
                writecell({'Raman Scale'},[Path Filename],'sheet','Normalized Fingerprint Spectra','range','A1');
                writematrix(RamanWavenumber(FPStart:FPEnd),[Path Filename],'sheet','Normalized Fingerprint Spectra','range','A2');
                writecell({'Raman Scale'},[Path Filename],'sheet','Processed Highwave Spectra','range','A1');
                writematrix(RamanWavenumber(HWStart:HWEnd),[Path Filename],'sheet','Processed Highwave Spectra','range','A2');
                writecell({'Raman Scale'},[Path Filename],'sheet','Normalized Highwave Spectra','range','A1');
                writematrix(RamanWavenumber(HWStart:HWEnd),[Path Filename],'sheet','Normalized Highwave Spectra','range','A2');
                if RTComposition.Value == 1
                    writecell({'Raman Scale'},[Path Filename],'sheet','Composition','range','A2');
                    writematrix(RamanWavenumber(FPStart:FPEnd),[Path Filename],'sheet','Composition','range','A3');
                end
                % Output Spectrum parameters
                SelectedFiles = AnaTable.Data(cell2mat(AnaTable.Data(:,1)),5);
                DateMatrix = cell(1,length(SelectedFiles));
                PatientIDMatrix = cell(1,length(SelectedFiles));
                SessionNumberMatrix = cell(1,length(SelectedFiles));
                SessionNameMatrix = cell(1,length(SelectedFiles));
                if RTComposition.Value == 1
                    CompositionMatrix = [];
                    CompositionCell = {};
                    CompositionFile = cell(1,length(SelectedFiles)*length(nonzeros(cell2mat(ComponentTable.Data(:,1)) == 1)));
                end
                for i = 1:size(SelectedFiles,1)
                    OneFile = importdata(fullfile(AnaTableDirectory,char(SelectedFiles(i,1))));
                    RawSpectra(:,i) = OneFile.Spectrum;
                    DateMatrix{i,1} = OneFile.Date;
                    IntegrationTimeMatrix(i,1) = OneFile.Integration;
                    Scan2Avematrix(i,1) = OneFile.Scan2Average;
                    PatientIDMatrix{i,1} = OneFile.PatientID;
                    SessionNumberMatrix{i,1} = OneFile.SessionNumber;
                    SessionNameMatrix{i,1} = OneFile.SessionName;
                    % Preprocess
                    Fingerprint_Spectra_crop = RawSpectra(FPStart:FPEnd,i);
                    Highwave_Spectra_crop = RawSpectra(HWStart:HWEnd,i);
                    if BGSubtraction.Value == 1 && isempty(BGSpec) == 0
                        Fingerprint_Spectra_noBG = Fingerprint_Spectra_crop - BGSpec(FPStart:FPEnd,1);
                        Highwave_Spectra_noBG = Highwave_Spectra_crop - BGSpec(HWStart : HWEnd,1);
                    else
                        Fingerprint_Spectra_noBG = Fingerprint_Spectra_crop;
                        Highwave_Spectra_noBG = Highwave_Spectra_crop;
                    end
                    Fingerprint_Spectra_smoothed = sgolayfilt(Fingerprint_Spectra_noBG',1,SavFilter.Value); % Filter Operating row-wise
                    Highwave_Spectra_smoothed = sgolayfilt(Highwave_Spectra_noBG',1,SavFilter.Value);
                    Fingerprint_Spectra_processed(:,i) = Correct_fit(Fingerprint_Spectra_smoothed,FPBaseline.Value)';
                    Highwave_Spectra_processed(:,i) = Correct_fit(Highwave_Spectra_smoothed,HWBaseline.Value)';
                    Fingerprint_Spectra_normalized(:,i) = Fingerprint_Spectra_processed(:,i)/trapz(Fingerprint_Spectra_processed(:,i));
                    Highwave_Spectra_normalized(:,i) = Highwave_Spectra_processed(:,i)/trapz(Highwave_Spectra_processed(:,i));
                    % Highwave area
                    CHArea(i,1) = trapz(Highwave_Spectra_normalized(1:134,i)); %2600cm-1 -- 3050 cm-1
                    OHArea(i,1) = trapz(Highwave_Spectra_normalized(135:318,i)); %3050cm-1 -- 3600 cm-1
                    if RTRegression.Value == 1 % Real time regression checkbox is checked 
                        writecell(SelectedFiles(i,1),[Path Filename],'sheet','Analysis Result','range',['A' num2str(i+1)]);
                        % Output Scores
                        Scores(i,:) = lsqnonneg(ComponentRegression,Fingerprint_Spectra_normalized(:,i));
                        ComponentIndex = cell2mat(ComponentTable.Data(:,1)) == 1;
                        % Output Rsquare
                        OneConstituent(:,1) = zeros(size(RamanWavenumber(FPStart:FPEnd)'));
                        for j = 1:size(Scores,2)
                            OneConstituent(:,j+1) = Scores(i,j)*ComponentRegression(:,j) + OneConstituent(:,j);
                        end
                        [~,~,~,~,stats] = regress(Fingerprint_Spectra_normalized(:,i),[ones(length(OneConstituent(:,end)),1) OneConstituent(:,end)]);
                        RsqureMatrix(i,1) = stats(1);
                        if RTComposition.Value == 1 % Real time composition checkbox is checked 
                            OneConstituent = OneConstituent(:,2:end);
                            OneConstituent = OneConstituent(:,ComponentIndex);
                            CompositionFile{1,length(nonzeros(ComponentIndex))*(i-1)+1} = string(SelectedFiles(i,1));
                            CompositionMatrix = [CompositionMatrix OneConstituent];
                            CompositionCell = [CompositionCell ComponentTable.Data(ComponentIndex,2)'];
                        end
                    end
                end
                if BGSubtraction.Value == 1 % if there is a background available for subtration
                    % Output the background with the Raw Spectrum
                    writecell({'Background for Subtraction'},[Path Filename],'sheet','Raw Spectra','range','B1');
                    writematrix(BGSpec,[Path Filename],'sheet','Raw Spectra','range','B2');
                    writecell(SelectedFiles',[Path Filename],'sheet','Raw Spectra','range','C1');
                    writematrix(RawSpectra,[Path Filename],'sheet','Raw Spectra','range','C2');
                else
                    writecell(SelectedFiles',[Path Filename],'sheet','Raw Spectra','range','B1');
                    writematrix(RawSpectra,[Path Filename],'sheet','Raw Spectra','range','B2');
                end
                % Output spectrum vectors
                writecell(SelectedFiles',[Path Filename],'sheet','Processed Fingerprint Spectra','range','B1');
                writematrix(Fingerprint_Spectra_processed,[Path Filename],'sheet','Processed Fingerprint Spectra','range','B2');
                writecell(SelectedFiles',[Path Filename],'sheet','Processed Highwave Spectra','range','B1');
                writematrix(Highwave_Spectra_processed,[Path Filename],'sheet','Processed Highwave Spectra','range','B2');
                writecell(SelectedFiles',[Path Filename],'sheet','Normalized Fingerprint Spectra','range','B1');
                writematrix(Fingerprint_Spectra_normalized,[Path Filename],'sheet','Normalized Fingerprint Spectra','range','B2');
                writecell(SelectedFiles',[Path Filename],'sheet','Normalized Highwave Spectra','range','B1');
                writematrix(Highwave_Spectra_normalized,[Path Filename],'sheet','Normalized Highwave Spectra','range','B2');
                writecell(SelectedFiles,[Path Filename],'sheet','Analysis Result','range','A2');
                if RTRegression.Value == 1 
                    % Output Analysis result 
                    writecell({'Date'},[Path Filename],'sheet','Analysis Result','range','B1');
                    writecell(DateMatrix,[Path Filename],'sheet','Analysis Result','range','B2');
                    writecell({'Patient ID'},[Path Filename],'sheet','Analysis Result','range','C1');
                    writecell(PatientIDMatrix,[Path Filename],'sheet','Analysis Result','range','C2');
                    writecell({'SessionName'},[Path Filename],'sheet','Analysis Result','range','D1');
                    writecell(SessionNameMatrix,[Path Filename],'sheet','Analysis Result','range','D2');
                    writecell({'Session Number'},[Path Filename],'sheet','Analysis Result','range','E1');
                    writecell(SessionNumberMatrix,[Path Filename],'sheet','Analysis Result','range','E2');
                    writecell({'Integration Time'},[Path Filename],'sheet','Analysis Result','range','F1');
                    writematrix(IntegrationTimeMatrix,[Path Filename],'sheet','Analysis Result','range','F2');
                    writecell({'Scan2Average'},[Path Filename],'sheet','Analysis Result','range','G1');
                    writematrix(Scan2Avematrix,[Path Filename],'sheet','Analysis Result','range','G2');
                    writecell(ComponentTable.Data(ComponentIndex,2)',[Path Filename],'sheet','Analysis Result','range','H1');
                    writematrix(Scores(:,ComponentIndex),[Path Filename],'sheet','Analysis Result','range','H2');
                    writecell({'RSquare'},[Path Filename],'sheet','Analysis Result','range',[char(72+length(nonzeros(ComponentIndex))) '1']);
                    writematrix(RsqureMatrix,[Path Filename],'sheet','Analysis Result','range',[char(72+length(nonzeros(ComponentIndex))) '2']);
                    writecell({'CHArea (2600-3050)'},[Path Filename],'sheet','Analysis Result','range',[char(72+length(nonzeros(ComponentIndex))+1) '1']);
                    writematrix(CHArea,[Path Filename],'sheet','Analysis Result','range',[char(72+length(nonzeros(ComponentIndex))+1) '2']);
                    writecell({'OHArea (3050-3600)'},[Path Filename],'sheet','Analysis Result','range',[char(72+length(nonzeros(ComponentIndex))+2) '1']);
                    writematrix(OHArea,[Path Filename],'sheet','Analysis Result','range',[char(72+length(nonzeros(ComponentIndex))+2) '2']);
                    writecell({'OH/CH Ratio'},[Path Filename],'sheet','Analysis Result','range',[char(72+length(nonzeros(ComponentIndex))+3) '1']);
                    writematrix(OHArea./CHArea,[Path Filename],'sheet','Analysis Result','range',[char(72+length(nonzeros(ComponentIndex))+3) '2']);
                else
                    % when no regression or composition is selected
                    writecell({'Date'},[Path Filename],'sheet','Analysis Result','range','B1');
                    writecell(DateMatrix,[Path Filename],'sheet','Analysis Result','range','B2');
                    writecell({'Patient ID'},[Path Filename],'sheet','Analysis Result','range','C1');
                    writecell(PatientIDMatrix,[Path Filename],'sheet','Analysis Result','range','C2');
                    writecell({'SessionName'},[Path Filename],'sheet','Analysis Result','range','D1');
                    writecell(SessionNameMatrix,[Path Filename],'sheet','Analysis Result','range','D2');
                    writecell({'Session Number'},[Path Filename],'sheet','Analysis Result','range','E1');
                    writecell(SessionNumberMatrix,[Path Filename],'sheet','Analysis Result','range','E2');
                    writecell({'Integration Time'},[Path Filename],'sheet','Analysis Result','range','F1');
                    writematrix(IntegrationTimeMatrix,[Path Filename],'sheet','Analysis Result','range','F2');
                    writecell({'Scan2Average'},[Path Filename],'sheet','Analysis Result','range','G1');
                    writematrix(Scan2Avematrix,[Path Filename],'sheet','Analysis Result','range','G2');
                    writecell({'CHArea (2600-3050)'},[Path Filename],'sheet','Analysis Result','range','H1');
                    writematrix(CHArea,[Path Filename],'sheet','Analysis Result','range','H2');
                    writecell({'OHArea (3050-3600)'},[Path Filename],'sheet','Analysis Result','range','I1');
                    writematrix(OHArea,[Path Filename],'sheet','Analysis Result','range','I2');
                    writecell({'OH/CH Ratio'},[Path Filename],'sheet','Analysis Result','range','J1');
                    writematrix(OHArea./CHArea,[Path Filename],'sheet','Analysis Result','range','J2');
                end
                if RTComposition.Value == 1 
                    % Output composition, following:
                    % [ref1*score ref1*score1+ref2*scores ref1*score1+ref2*scores+ref3*scores3]
                    writecell(CompositionFile,[Path Filename],'sheet','Composition','range','B1');
                    writecell(CompositionCell,[Path Filename],'sheet','Composition','range','B2');
                    writematrix(CompositionMatrix,[Path Filename],'sheet','Composition','range','B3');
                end
            end
            if isempty(ComponentTable.Data) == 0 % Output Component Table
                for i = 1:length(ComponentTable.Data(:,2))
                    writecell(ComponentTable.Data(i,2)',[Path Filename],'sheet','Components','range',[char(65+i) '1']);
                    writematrix(Component(:,i),[Path Filename],'sheet','Components','range',[char(65+i) '2']);
                end
                writecell({'Raman Scale'},[Path Filename],'sheet','Components','range','A1');
                writematrix(RamanWavenumber(FPStart:FPEnd),[Path Filename],'sheet','Components','range','A2');
            end
            disp('Export Finished!');
        end
    end
    function ImportComponentFcn()
        % Import regressional component
        [Files,path] = uigetfile('*.mat','Select the Components for regression','MultiSelect', 'on');
        if iscell(Files) % if multiple file is selected
            Checkbox = cell(length(Files),1);
            Names = cell(length(Files),1);
            StartScore = cell(length(Files),1);
            for i = 1:length(Files)
                Component(:,i) = importdata(fullfile(path,string(Files(1,i))));
                Checkbox{i,1} = true;
                Names{i,1} = Files{1,i};
                StartScore{i,1} = 0;
            end
        else % if only one file is selected
            Component = importdata(fullfile(path,string(Files)));
            Names = {Files};
            Checkbox = {true};
            StartScore = {0};
        end
        
        % making the componentTable and appearance adjustments
        Data =  [Checkbox Names StartScore];
        ComponentTable.Data = Data;
        ComponentRegression = Component;
        RTRegression.Enable = 'on';
        RTRegression.Value = 1;
        RTComposition.Enable = 'on';
        
        % Add color to indicate component on plots for composition 
        ComponentColor = uistyle;
        ComponentColor.FontWeight = 'bold';
        for i = 1:size(Component,2)
            ComponentColor.FontColor = Colormat(i,:);
            addStyle(ComponentTable,ComponentColor,'row',i);
        end
    end
    function ObtainBackgroundFcn()
        % To take a single background
        ObtainBackground.Text = 'Background Obtained';
        ObtainBackground.BackgroundColor = 'r';
        ObtainBackground.Enable = 'off';
        BGSpec = []; 
        wrapper.setIntegrationTime(0, 1000000 * IntegrationTime.Value);
        wrapper.setScansToAverage(0, Scan2Average.Value);      
        pause(IntegrationTime.Value+1)
        BGSpec = wrapper.getSpectrum(0);
        
        % Automatically choose background subtraction after obtained one
        BGSubtraction.Enable = 'on';
        BGSubtraction.Value = 1;
        
        % Package BGSpectrum to correct folder 
        CurrentTime = char(datetime);
        CurrentTime = strrep(CurrentTime,':', '-');
        OneBackground = struct('Spectrum',BGSpec,...
                               'Date',CurrentTime,...
                               'Integration',IntegrationTime.Value,...
                               'Scan2Average',Scan2Average.Value,...
                               'PatientID',['void'],...
                               'SessionNumber',['void'],...
                               'SessionName',['void']);
        
        SavingDirectory = [BGTableDirectory '/' CurrentTime];
        save(SavingDirectory,'OneBackground');
        
        % Display on BGTable
        if isempty(BGTable.Data)
            Data = [{true} {CurrentTime} {IntegrationTime.Value} {Scan2Average.Value} {[CurrentTime '.mat']}];
            BGTable.Data = Data;
        else
            BGTable.Data(:,1) = {false};
            Data = [{true} {CurrentTime} {IntegrationTime.Value} {Scan2Average.Value} {[CurrentTime '.mat']}];
            BGTable.Data(end+1,:) = Data;
        end
        
    end
    function Preprocess(Raw_Spectra,Background,Tag)
        if isempty(Raw_Spectra) == 1 % if there is no spectrum input, terminate
            return;
        end
        
        % Crop Spectra into fingerprint and highwave region
        Fingerprint_Spectra_crop = Raw_Spectra(FPStart:FPEnd,1);
        Highwave_Spectra_crop = Raw_Spectra(HWStart:HWEnd,1);
        
        % Background Subtraction
        if BGSubtraction.Value == 1 && isempty(BGSpec) == 0
            Fingerprint_Spectra_noBG = Fingerprint_Spectra_crop(:,1) - Background(FPStart:FPEnd,1);
            Highwave_Spectra_noBG = Highwave_Spectra_crop(:,1) - Background(HWStart : HWEnd,1);
        else
            Fingerprint_Spectra_noBG = Fingerprint_Spectra_crop(:,1);
            Highwave_Spectra_noBG = Highwave_Spectra_crop(:,1);
        end
        
        % SavGol filter
        Fingerprint_Spectra_smoothed = sgolayfilt(Fingerprint_Spectra_noBG(:,1)',1,SavFilter.Value); % Filter Operating row-wise
        Highwave_Spectra_smoothed = sgolayfilt(Highwave_Spectra_noBG(:,1)',1,SavFilter.Value);
        
        % Correct_fit: function for baseline subtraction
        Fingerprint_Spectra_processed = Correct_fit(Fingerprint_Spectra_smoothed,FPBaseline.Value)';
        Highwave_Spectra_processed = Correct_fit(Highwave_Spectra_smoothed,HWBaseline.Value)';
        
        % Normalization
        Fingerprint_Spectra_normalized = Fingerprint_Spectra_processed/trapz(Fingerprint_Spectra_processed);
        Highwave_Spectra_normalized = Highwave_Spectra_processed/trapz(Highwave_Spectra_processed); 
        
        % Plotting
        if ContinuousAcquisition.Value == 1 % real time process
            if RTRegression.Value == 1 % Regression
                Scores = Analysis(Fingerprint_Spectra_normalized');
                if RTComposition.Value == 1 % Composition
                    Fingerprint.NextPlot = 'replacechildren';
                    plot(Fingerprint,RamanWavenumber(FPStart:FPEnd),Fingerprint_Spectra_normalized,'Tag',Tag,'Color',Colormat(1,:));
                    Composition(Scores); % Plot composition 
                end
            end
            plot(Fingerprint,RamanWavenumber(FPStart:FPEnd),Fingerprint_Spectra_normalized,'Tag',Tag,'Color',Colormat(1,:));
            plot(Highwave,RamanWavenumber(HWStart:HWEnd),Highwave_Spectra_normalized,'Tag',Tag,'Color',Colormat(1,:));
            drawnow;
        elseif ProcessMode.Value == 1 % process when in processing mode
            if RTRegression.Value == 1 % Regression
                Scores = Analysis(Fingerprint_Spectra_normalized');
                if RTComposition.Value == 1 % Composition
                    Composition(Scores);
                end
            end
            plot(Fingerprint,RamanWavenumber(FPStart:FPEnd),Fingerprint_Spectra_normalized,'Tag',Tag,'Color',Colormat(1,:));
            plot(Highwave,RamanWavenumber(HWStart:HWEnd),Highwave_Spectra_normalized,'Tag',Tag,'Color',Colormat(1,:));
            % Correct color to be same as on the table
            RawColor = findobj(Raw.Children,'Tag',Tag);
            FingerprintColor = findobj(Fingerprint.Children,'Tag',Tag);
            HighwaveColor = findobj(Highwave.Children,'Tag',Tag);
            FingerprintColor.Color = RawColor.Color;
            HighwaveColor.Color = RawColor.Color;
        else %adjustment for stopping continuous acquisition 
            RawSpec = [];
            delete(Raw.Children);
            delete(Fingerprint.Children);
            delete(Highwave.Children);
            if isempty(ComponentTable.Data) == 0
                ComponentTable.Data(:,3) = num2cell(zeros(size(ComponentTable.Data(:,3))));
            end
            Rsquare.Value = 0;
            return;
        end
        
        function Scores = Analysis(Fingerprint_Spectra_normalized)
            % regression and display scores on component table 
            Scores = lsqnonneg(ComponentRegression,Fingerprint_Spectra_normalized);
            ComponentTable.Data(:,3) = num2cell(Scores);
        end
        
        function Composition(Scores)
            % Calculate Rsquare and composition 
            OneConstituent(:,1) = zeros(size(RamanWavenumber(FPStart:FPEnd)'));
            for i = 1:size(Scores,1)
                OneConstituent(:,i+1) = Scores(i,1)*ComponentRegression(:,i) + OneConstituent(:,i);
            end
            Fingerprint.NextPlot = 'add';
            for i = (size(Scores,1)+1):-1:2
                area(Fingerprint,RamanWavenumber(FPStart:FPEnd),OneConstituent(:,i),'Tag',['Composition' Tag],...
                    'FaceColor',ComponentTable.StyleConfigurations.Style(i-1,1).FontColor);
            end
            Temp = [ones(length(OneConstituent(:,end)),1) OneConstituent(:,end)];
            [~,~,~,~,stats] = regress(Fingerprint_Spectra_normalized',Temp);
            Rsquare.Value = stats(1);
        end
        
    end
    function ProcessModeFcn()
        if ProcessMode.Value == 1 % system in processing mode to view obtained data 
            ProcessMode.BackgroundColor = 'g';
            ObtainBackground.Enable = 'off';
            ObtainBackground.Text = 'Obtain Background';
            ObtainBackground.BackgroundColor = [0.9600 0.9600 0.9600];
            ContinuousAcquisition.Enable = 'off';
            Raw.NextPlot = 'add';
            Fingerprint.NextPlot = 'add';
            Highwave.NextPlot = 'add';
            ContinuousSave.Enable = 'off';
            ExportResult.Enable = 'on';
            DeleteBG.Enable = 'off';
            DeleteSpectrum.Enable = 'off';
            SaveSpectrum.Enable = 'off';
            BGTable.Data(:,1) = {false};
            AnaTable.Data(:,1) = {false};
            BGSubtraction.Value = 0;
            ReadFolder(AnaTable,AnaTableDirectory);
            ReadFolder(BGTable,BGTableDirectory);
        else %Adjustment for back to acquisition mode
            ProcessMode.BackgroundColor = [0.9600 0.9600 0.9600];
            ObtainBackground.Enable = 'on';
            ContinuousAcquisition.Enable = 'on';
            Raw.NextPlot = 'replacechildren';
            Highwave.NextPlot = 'replacechildren';
            Fingerprint.NextPlot = 'replacechildren';
            BGSubtraction.Enable = 'off';
            ContinuousSave.Enable = 'on';
            ExportResult.Enable = 'off';
            RTRegression.Value = 0;
            RTComposition.Value = 0;
            RTComposition.Enable = 'off';
            BGSubtraction.Value = 0;
            BGTable.Data(:,1) = {false};
            AnaTable.Data(:,1) = {false};
            BGSpec = [];
            RawSpec = [];
            removeStyle(BGTable);
            removeStyle(AnaTable);
            delete(Raw.Children);
            delete(Fingerprint.Children);
            delete(Highwave.Children);
            ReadFolder(AnaTable,AnaTableDirectory);
            ReadFolder(BGTable,BGTableDirectory);
        end
        if isempty(ComponentTable.Data) == 0 
           ComponentTable.Data(:,3) = num2cell(zeros(size(ComponentTable.Data(:,3)))); 
        end
    end
    function ReadFolder(OneTable,OneDirectory)
        % Read and import data filename in both background and saved spectrum folder by passing
        % the name and directory of a table
        Files = dir(fullfile(OneDirectory,'*.mat'));
        if isempty(Files) == 0 % when the folder is not empty
            Data = cell(length(Files),5);
            for i = 1:length(Files)
                OneFile = importdata(fullfile(OneDirectory,Files(i,1).name));
                Data(i,:) = [{false} {OneFile.Date} {OneFile.Integration} {OneFile.Scan2Average} {Files(i,1).name}];
            end
            OneTable.Data = Data;
        else
            OneTable.Data = {};
        end
    end
    function ResetPatientFcn()
        PatientID.Value = '000000';
        SessionNum.Value = '000000';
        SessionName.Value = 'default';
    end
    function RTComFcn()
        % Real time composition plotting adjustment 
        if ProcessMode.Value ~= 1 
            if RTComposition.Value == 1 % multiple plot avaiable if doing composition 
                Fingerprint.NextPlot = 'add';
            else % otherwise only one plot at a time 
                Fingerprint.NextPlot = 'replacechildren';
                Rsquare.Value = 0;
            end
        end
    end
    function RTRegFcn()
        if RTRegression.Value == 1 
            RTComposition.Enable = 'on';
        else
            RTComposition.Value = 0;
            RTComposition.Enable = 'off';
            if ContinuousAcquisition.Value == 1
               Fingerprint.NextPlot = 'replacechildren'; 
            end
            if isempty(ComponentTable.Data) == 0 
                ComponentTable.Data(:,3) = num2cell(zeros(size(ComponentTable.Data(:,3))));
            end
            Rsquare.Value = 0;
        end
    end
    function SaveSpectrumFcn()
        % Package BGSpectrum to correct folder
        CurrentTime = char(datetime);
        CurrentTime = strrep(CurrentTime,':', '-');
        OneSpectrum = struct('Spectrum',RawSpec,...
            'Date',CurrentTime,...
            'Integration',IntegrationTime.Value,...
            'Scan2Average',Scan2Average.Value,...
            'PatientID',PatientID.Value,...
            'SessionNumber',SessionNum.Value,...
            'SessionName',SessionName.Value);
        % check if the file name is existed, if exist, put a numerical postfix
        Counter = 1;
        NewName = [PatientID.Value '-' SessionNum.Value '-' SessionName.Value '-' num2str(Counter)];
        while exist([AnaTableDirectory '/' [NewName '.mat']],'file') == 2
            NewName = [PatientID.Value '-' SessionNum.Value '-' SessionName.Value '-' num2str(Counter)];
            Counter = Counter + 1;
        end
        % save 
        SavingDirectory = [AnaTableDirectory '/' [NewName '.mat']];
        save(SavingDirectory,'OneSpectrum');
        
        % Display on AnaTable
        Data = [{false} {CurrentTime} {IntegrationTime.Value} {Scan2Average.Value} {[NewName '.mat']}];
        if isempty(AnaTable.Data) == 1
            AnaTable.Data = Data;
        else
            AnaTable.Data(end+1,:) = Data;
        end
        
        SaveSpectrum.Enable = 'off';
    end
    function SelectBGFcn(event)
        if ProcessMode.Value == 1 && event.Indices(1,2) ~= 5 % If in processing mode
            Tag = ['BG' num2str(event.Indices(1,1))];
            SelectedBG = uistyle;
            SelectedBG.BackgroundColor = 'y';
            PlottedBG = uistyle;
            PlottedBG.FontWeight = 'bold';
            if cell2mat(BGTable.Data(event.Indices(1,1),event.Indices(1,2))) == 1 % when a file is selected
                RemovalIndex = BGTable.StyleConfigurations.Target == 'cell';
                IndexVector = linspace(1,size(BGTable.StyleConfigurations,1),size(BGTable.StyleConfigurations,1));
                if isempty(IndexVector(RemovalIndex)) == 0
                    removeStyle(BGTable,IndexVector(RemovalIndex));
                end
                addStyle(BGTable,SelectedBG,'cell',[event.Indices(1,1),2]);
                OneFile = importdata(fullfile(BGTableDirectory,char(BGTable.Data(event.Indices(1,1),5))));
                BGSpec = OneFile.Spectrum;
                plot(Raw,Wavelength,BGSpec,'Tag',Tag );
                PlottedBG.FontColor = findobj(Raw.Children,'Tag',Tag).Color;
                addStyle(BGTable,PlottedBG,'row',event.Indices(1,1));
                BGSubtraction.Value = 1;
                BGSubtraction.Enable = 'on';
            else 
                delete(findobj(Raw.Children,'Tag',Tag))
                if sum(cell2mat(BGTable.Data(:,1))) == 0 % when no file is selected
                    BGSpec = [];
                    BGSubtraction.Enable = 'off';
                    BGSubtraction.Value = 0;
                    removeStyle(BGTable);
                else 
                    Temp = find(BGTable.StyleConfigurations.Target == 'row');
                    RemovalIndex = cell2mat(BGTable.StyleConfigurations.TargetIndex(Temp,1));
                    removeStyle(BGTable,Temp(RemovalIndex == event.Indices(1,1)));
                    % Check if selection is the same as highlight
                    Temp = find(BGTable.StyleConfigurations.Target == 'cell');
                    CurrentIndex = cell2mat(BGTable.StyleConfigurations.TargetIndex(Temp,1));
                    if CurrentIndex(1,1) == event.Indices(1,1)
                        removeStyle(BGTable,Temp);
                        FirstSelected = find(cell2mat(BGTable.Data(:,1)),1);
                        OneFile = importdata(fullfile(BGTableDirectory,char(BGTable.Data(FirstSelected,5))));
                        BGSpec = OneFile.Spectrum;
                        addStyle(BGTable,SelectedBG,'cell',[FirstSelected,2]);
                    end
                end
            end
            return
        end
        if event.Indices(1,2) == 1 % Background selection
            if sum(cell2mat(BGTable.Data(:,1))) == 0 
                ReadFolder(BGTable,BGTableDirectory);
                BGSpec = [];
                BGTable.Data(:,1) = {false};
                ObtainBackground.Text = 'Obtain Background';
                ObtainBackground.BackgroundColor = [0.9600 0.9600 0.9600];
                if ContinuousAcquisition.Value == 0
                    ObtainBackground.Enable = 'on';
                end 
                BGSubtraction.Enable = 'off';
                BGSubtraction.Value = 0;
            elseif sum(cell2mat(BGTable.Data(:,1))) > 1
                BGTable.Data(event.Indices(1,1),1) = {false};
            else
                ReadFolder(BGTable,BGTableDirectory);
                BGTable.Data(:,1) = {false};
                BGTable.Data(event.Indices(1,1),1) = {true};
                OneFile = importdata(fullfile(BGTableDirectory,char(BGTable.Data(event.Indices(1,1),5))));
                BGSpec = OneFile.Spectrum;
                ObtainBackground.Text = 'Background Obtained';
                ObtainBackground.BackgroundColor = 'r';
                ObtainBackground.Enable = 'off';
                BGSubtraction.Enable = 'on';
                BGSubtraction.Value = 1;
                DeleteBG.Enable = 'off';
            end
            return
        end
        if event.Indices(1,2) == 5 % Change Filename
            NewName = [char(BGTable.Data(event.Indices(1,1),event.Indices(1,2)))];   
            if exist([BGTableDirectory '/' [NewName '.mat']],'file') == 2
                BGTable.Data(event.Indices(1,1),event.Indices(1,2)) = {event.PreviousData};
            else
                movefile(fullfile(BGTableDirectory,event.PreviousData),fullfile(BGTableDirectory, NewName));
                BGTable.Data(event.Indices(1,1),event.Indices(1,2)) = {NewName};
            end
            return
        end
    end
    function SelectComponentFcn()
        % for regression component
        ComponentRegression = Component;
        TableIndex = cell2mat(ComponentTable.Data(:,1));
        ComponentRegression(:,TableIndex == 0) = 0;
        if sum(TableIndex) == 0
            RTRegression.Value = 0;
            RTRegression.Enable = 'off';
            RTComposition.Value = 0;
            RTComposition.Enable = 'off';
            ComponentTable.Data(:,3) = num2cell(zeros(size(ComponentTable.Data(:,3))));
        else
            RTRegression.Enable = 'on';
        end
    end
    function SelectDirectoryFcn()
        % customize directory
        selpath = uigetdir;
        cd(selpath);
        CurrentDirectory = selpath;
        DirectoryLabel.Text = CurrentDirectory;
        BGTableDirectory = [CurrentDirectory '/Background'];
        AnaTableDirectory = [CurrentDirectory '/Saved Spectrum'];
    end
    function SelectSpectrumFcn(event)
        if ProcessMode.Value == 1 && event.Indices(1,2) == 1  % If in processing mode
            Tag = ['Spec' num2str(event.Indices(1,1))];
            SelectedSpec = uistyle;
            SelectedSpec.FontWeight = 'bold';
            ScoreSpec = uistyle;
            ScoreSpec.BackgroundColor = 'y';
            if cell2mat(AnaTable.Data(event.Indices(1,1),event.Indices(1,2))) == 1
                RemovalIndex = AnaTable.StyleConfigurations.Target == 'cell';
                IndexVector = linspace(1,size(AnaTable.StyleConfigurations,1),size(AnaTable.StyleConfigurations,1));
                if isempty(AnaTable.StyleConfigurations) == 0
                    removeStyle(AnaTable,IndexVector(RemovalIndex));
                end
                addStyle(AnaTable,ScoreSpec,'cell',[event.Indices(1,1),2]);
                OneFile = importdata(fullfile(AnaTableDirectory,char(AnaTable.Data(event.Indices(1,1),5))));
                RawSpec = OneFile.Spectrum;
                plot(Raw,Wavelength,RawSpec,'Tag',Tag );
                SelectedSpec.FontColor = findobj(Raw.Children,'Tag',Tag).Color;
                addStyle(AnaTable,SelectedSpec,'row',event.Indices(1,1));
                delete(findobj(Fingerprint.Children,'Tag',Tag));
                delete(findobj(Fingerprint.Children,'Tag',['Composition' Tag]));
                delete(findobj(Highwave.Children,'Tag',Tag));
                Preprocess(RawSpec,BGSpec,Tag)
            else
                delete(findobj(Raw.Children,'Tag',Tag));
                delete(findobj(Fingerprint.Children,'Tag',Tag));
                delete(findobj(Fingerprint.Children,'Tag',['Composition' Tag]));
                delete(findobj(Highwave.Children,'Tag',Tag));
                if sum(cell2mat(AnaTable.Data(:,1))) == 0
                    RawSpec = [];
                    removeStyle(AnaTable);  
                    if isempty(ComponentTable.Data) == 0
                        ComponentTable.Data(:,3) = num2cell(zeros(size(ComponentTable.Data(:,3))));
                        Rsquare.Value = 0;
                    end
                else
                    Temp = find(AnaTable.StyleConfigurations.Target == 'row');
                    RemovalIndex = cell2mat(AnaTable.StyleConfigurations.TargetIndex(Temp,1));
                    removeStyle(AnaTable,Temp(RemovalIndex == event.Indices(1,1)));
                    % Check if selection is the same as highlight
                    Temp = find(AnaTable.StyleConfigurations.Target == 'cell');
                    CurrentIndex = cell2mat(AnaTable.StyleConfigurations.TargetIndex(Temp,1));
                    if CurrentIndex(1,1) == event.Indices(1,1)
                        removeStyle(AnaTable,Temp);
                        FirstSelected = find(cell2mat(AnaTable.Data(:,1)),1);
                        OneFile = importdata(fullfile(AnaTableDirectory,char(AnaTable.Data(FirstSelected,5))));
                        RawSpec = OneFile.Spectrum;
                        addStyle(AnaTable,ScoreSpec,'cell',[FirstSelected,2]);
                        Tag = ['Spec' num2str(FirstSelected)];
                        delete(findobj(Fingerprint.Children,'Tag',Tag));
                        delete(findobj(Fingerprint.Children,'Tag',['Composition' Tag]));
                        delete(findobj(Highwave.Children,'Tag',Tag));
                        Preprocess(RawSpec,BGSpec,Tag);
                    end
                end
            end
            return
        else
            AnaTable.Data(event.Indices(1,1),1) = {false};
        end
        if event.Indices(1,2) == 5 % Change Filename
            NewName = [char(AnaTable.Data(event.Indices(1,1),event.Indices(1,2)))];   
            if exist([AnaTableDirectory '/' [NewName '.mat']],'file') == 2
                AnaTable.Data(event.Indices(1,1),event.Indices(1,2)) = {event.PreviousData};
            else
                movefile(fullfile(AnaTableDirectory,event.PreviousData),fullfile(AnaTableDirectory, NewName));
                AnaTable.Data(event.Indices(1,1),event.Indices(1,2)) = {NewName};
            end
        end
    end
    function SpaceSaveSpectrumFcn(event)
        % save spectrum during continuous acquisition by pressing space,
        % must focus on the interface
        if ContinuousAcquisition.Value == 1 
            if isequal(event.Key,'space') && SaveSpectrum.Enable == 1
                SaveSpectrumFcn(); 
            end
        end
    end
    function TerminateRestartFcn()
        % quick way to restart the interface
        wrapper.closeAllSpectrometers();
        delete(Main);
        RTRamanProcess;
        return;
    end
end
