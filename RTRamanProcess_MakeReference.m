% Import Background
[BG,BGPath] = uigetfile('*.txt','Please Select Background');
if BG == 0 % selection cancel
    BG = zeros(1044,1);
else
   Background = importdata(fullfile(BGPath,BG)); % fullfile including path
   Background = Background.data(:,2); 
end

% Import Raw Spectrum
[RawFile,SpecPath] = uigetfile('*.txt','Select the files of interest');
Spectrum = importdata(fullfile(SpecPath,RawFile));
RawSpectrum = Spectrum.data(:,2);

NormalizedReference = Preprocess(RawSpectrum,Background);

% Get output directory
CurrentTime = char(datetime);
CurrentTime = strrep(CurrentTime,':', '-');
Filename = [CurrentTime '.mat'];
[Filename,OutputPath] = uiputfile(Filename);
save([OutputPath Filename],'NormalizedReference');

function FPSpecNormalized = Preprocess(RawSpectrum,Background)
Fingerprint_crop_start = 148; % Start cropping for the fingerprint range (in pixels)
Fingerprint_crop_end = 358 ; % End cropping for the fingerprint range (in pixels)

% Parameters
Smoothing_polynomia = 1; % Sav.Golay filter polynomial , keep it constant
SavGol_width = 3; % Sav.Golay filter window width. If noisy, change to "5"
Fingerprint_Polynom_order = 5; % Baseline subtraction polynmial order, fingerprint, keep constant.

% Crop Spectra into fingerprint and highwave region
Fingerprint_Spectra_crop = RawSpectrum(Fingerprint_crop_start:Fingerprint_crop_end,1);

% Background Subtraction
Fingerprint_Spectra_noBG = Fingerprint_Spectra_crop - Background(Fingerprint_crop_start:Fingerprint_crop_end,1);

% SavGol filter
Fingerprint_Spectra_smoothed = sgolayfilt(Fingerprint_Spectra_noBG',Smoothing_polynomia,SavGol_width); % Filter Operating row-wise

% Baseline Subtration & output processed
% Correct_fit: function for baseline subtraction
Fingerprint_Spectra_processed = Correct_fit(Fingerprint_Spectra_smoothed,Fingerprint_Polynom_order)';

% Normalization
FPSpecNormalized = Fingerprint_Spectra_processed/trapz(Fingerprint_Spectra_processed);

    function Spectra_Processed =  Correct_fit(Spectra_smoothed,Polynom_order)
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
end

