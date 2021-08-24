# RTRamanProcess

This code is for controlling QE pro CCD along with ocean optics omnidriver (here, windows, 64 bits). 
Here are a few steps need to run this code:
1. Install omnidriver, turn on QE pro spectrometer and connect to the computer
2. close other application (i.e oceanView) that could send commend to the spectrometer
3. Open "RealTimeRamanProcess.m" and click run
4. If encounter error, go to matlab's library path (example: C:\Program Files\MATLAB\R2021a\toolbox\local\librarypath.txt) and manually add the directory of your omnidriver directory into librarypath.txt (example: C:\Program Files\Ocean Optics\OmniDriver\OOI_HOME) 
5. Restart MATLAB and run again. 

For converting text file data from oceanview text file: 
1. Run "RTRamanProcess_Text2Mat.m"
2. In the first ui window, select a folder contains the text files
3. In the second ui window, select a directory where to place the .mat files
4. To view the .mat files in gui, recommend to have output .mat files in the "Saved Spectrum" folder.

For getting a new reference spectrum:
1. Run "RTRamanProcess_MakeReference.m"
2. In the first ui window, select a background spectrum for background subtraction. If cancel, no BG subtraction will be apply.
3. In the second ui window, select the raw reference file needed to be processed.
4. In the third ui window, select the output path and name the .mat reference spectrum.
5. To use the reference in gui, recommend to have output .mat reference in the "Reference Library" folder.

For any questions, please email andyzjc@Bu.edu. Have fun : ) 
