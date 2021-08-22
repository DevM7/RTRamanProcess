# RTRamanProcess

This code is for controlling QE pro CCD along with ocean optics omnidriver (here, windows, 64 bits). 
Here are a few steps need to run this code:
1. Install omnidriver, turn on QE pro spectrometer and connect to the computer
2. close other application (i.e oceanView) that could send commend to the spectrometer
3. Open "RealTimeRamanProcess.m" and click run
4. If encounter error, go to matlab's library path (example: C:\Program Files\MATLAB\R2021a\toolbox\local\librarypath.txt) and manually add the directory of your omnidriver directory into librarypath.txt (example: C:\Program Files\Ocean Optics\OmniDriver\OOI_HOME) 
5. Restart MATLAB and run again. 

For any questions, please email andyzjc@Bu.edu. Have fun : ) 
