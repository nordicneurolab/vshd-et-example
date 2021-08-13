%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%% Copyright NordicNeuroLab AS 2021 %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%% File:          gridTest.m
%% Init Author:   ”Carl Fredrik Haakonsen” <cfhaakonsen@gmail.com>
%% Init Date:     2021-08-12
%% Project:       Eye tracking testing
%% Description:   Psychtoolbox script for testing eye tracking on VSHD
%%
%% To run the script "screenNumber" must be set to the screen ID corresponding
%% to VSHD. Then the desired output filename must be set. Before running the 
%% script you must start recording the gaze data in Arrington/MRC. Run the 
%% script and then stop the recording when the testing is finished. The 
%% VSHD display should also be set as primary monitor for propper syncing with
%% Psychtoolbox. VSHD should be set to monoscopic view, setup 1M or 2M. 
%%
%% The script will show a number of points one-by-one on the screen. The 
%% test subject should fixate on using VSHD. The script will save the
%% coordinates and time interval they are shown. This is saved to a .csv file
%% so that it can be read easily in the analyzing scripts. 
%%
%% In the "Setup Parameters" you can set how much of the screen in x and y
%% direction should be used to test. The number of testing points can also
%% be changed here. The duration, size and color of the points can also be
%% changed.
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Clear the workspace and the screen
sca;
close all;
clearvars;

% Here we call some default settings for setting up Psychtoolbox
PsychDefaultSetup(2);

% Seed the random number generator. Here we use the an older way to be
% compatible with older systems. Newer syntax would be rng('shuffle').
% For help see: help rand
rand('seed', sum(100 * clock));

%Screen('Preference', 'SkipSyncTests', 0);
% Get the screen numbers. This gives us a number for each of the screens
% attached to our computer. For help see: Screen Screens?
screens = Screen('Screens');

%------------------------------------------------------------------------------
%                             SETUP PARAMETERS
%------------------------------------------------------------------------------

% Select screen
screenNumber = 1;

% Set the output filename for the output file containg point coordinates and
% time intervals. 
output_filename = 'demoRun.csv';

% The percentage of the screen in x and y directions used for calibration
calibPercentX = 0.5;
calibPercentY = 0.6;

% Number of calibation points in x and y directions
numPointsX = 3;
numPointsY = 3;

% Calibration time in seconds
calibTime = 2;

% Waiting time for the points before and after calibration
waitTime = 1;

% Dot size in pixels for dots before and during calibration
dotSizeLarge = 20;
dotSizeSmall = 10; 

% Dot size in RGB
dotColor = [1 1 1];

%------------------------------------------------------------------------------
%                           SETTING UP THE SCREEN
%------------------------------------------------------------------------------

% Define black and white (white will be 1 and black 0). This is because
% luminace values are (in general) defined between 0 and 1.
% For help see: help WhiteIndex and help BlackIndex
white = WhiteIndex(screenNumber);
black = BlackIndex(screenNumber);

% Open an on screen window and color it black.
% For help see: Screen OpenWindow?
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, black);

% Get the size of the on screen window in pixels.
% For help see: Screen WindowSize?
[screenXpixels, screenYpixels] = Screen('WindowSize', window);

% Get the centre coordinate of the window in pixels
% For help see: help RectCenter
[xCenter, yCenter] = RectCenter(windowRect);

% Enable alpha blending for anti-aliasing
Screen('BlendFunction', window, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);


% Dot positions.
edgeX = screenXpixels/2 * calibPercentX;
edgeY = screenYpixels/2 * calibPercentY;

dotXpos = linspace(-edgeX, edgeX, numPointsX) + xCenter;
dotYpos = linspace(-edgeY, edgeY, numPointsY) + yCenter;

dotPos =  [];

for i = 1:size(dotXpos, 2)
  for j = 1:size(dotYpos, 2)
    dotPos =  [dotPos [dotXpos(i); dotYpos(j)]];
  end
end

% Shuffle the dotPos Matrix for random display order when testing
dotPos = Shuffle(dotPos, 1);

%------------------------------------------------------------------------------
%                    DISPLAYING THE POINTS AND SAVING THE DATA
%------------------------------------------------------------------------------

% Initialize matrix for keeping time data
time_data = [];

for i = 1:size(dotPos, 2)
  % Displaying a large dot before testing the point
  Screen('DrawDots', window, dotPos(:,i), dotSizeLarge, dotColor, [], 2);
  Screen('Flip', window);
  WaitSecs(waitTime);
  
  % Displaying a smaller point indicating that the point is being tested
  Screen('DrawDots', window, dotPos(:,i), dotSizeSmall, dotColor, [], 2);
  Screen('Flip', window);
  
  % Getting the start time of the calibration of this point
  start_time = time();
  WaitSecs(calibTime);
  
  % Getting the end time of the calbration of this point
  end_time = time();
  
  % Drawing a larger dot indicating that the calibration of the point is finished
  Screen('DrawDots', window, dotPos(:,i), dotSizeLarge, dotColor, [], 2);
  Screen('Flip', window);
  
  % Adding the data the time_data matrix.
  time_data = [time_data; start_time end_time]; 
  WaitSecs(waitTime);
end

% Displaying text indicating that the test is finished. 
DrawFormattedText(window, 'Testing finished', 'center', 'center', [1 1 1 ]);
Screen('Flip', window);

% Wait before closing the program_invocation_name
WaitSecs(2);

% Save the file as a .csv so that it can be read easily later. 
csvwrite(output_filename, [dotPos', time_data]);

% Clear the screen.
sca;
