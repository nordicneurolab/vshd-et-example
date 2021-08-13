# vshd-et-example

This repository contains scripts and demo data for analying gaze tracking data from Arrington and MRC. 

## Running the tests

The file "gridTest.m" uses Psychtoolbox to one-by-one display a set of points that the test subject should fixate on. The location of the points as well as the time intervals they are displayed at are saved to a .csv file that is loaded in the analyzing scripts. Before running the script you must start gaze tracking with either Arrington or MRC. The gaze data from Arrington/MRC and the ground truth data from "gridTest.m" are feeded into the analyzing scripts.


By default "gridTest.m" uses 50% of the screen width and 60% of the screen height for testing. This is because the outer edges of the image may be hard to see.

## Analyzing Arrington data

The data from Arrington is analyzed in "analyzeDataArrington.m". Use a "normal adjustable window" (the other options may be buggy) in Arrington and make it full screen on VSHD. Use a monoscopic setup for VSHD, setup 1M or 2M. Define a smaller calibration region in before calibrating. Set up and calibrate the gaze tracking, and then start the recording. Once the recording is started, run "gridTest.m" on the VSHD display. Wait unntil the testing is finished, then stop recording in Arrington. The output files from both Arrington and "gridTest.m" can then be loaded into "analyzeDataArrington". The script will plot the gaze and ground truth data, as well as computing performance metrics. 


## Analyzing MRC data

The data from MRC is analyzed in "analyzeDataMRC". In MRC you cannot define a smaller calibration region, so you cannot use full screen on the window. Also, the placement of the window is a bit buggy. In the script an offset for the MRC data is set. This corresponds to the MRC window centered on the screen using 60% of the width and 70% of the height (10% more in both dimesions compared to "gridTest.m". In order to place it so, use the following data in MRC:
			
      [Position x, Position y, Width, Height] = [376, 149, 1153, 841]
 
I think this is only correct if the VSHD display is chosen as main monitor. Once this is done, set up and calibrate the gaze tracking. Start recording, and then run "gridTest.m" on the VSHD display. Wait until the test is finished and stop the recording. The output files from both MRC and "gridTest.m" can then be loaded into "analyzeDataMRC". The script will plot the gaze and ground truth data, as well as computing performance metrics. 
