%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%% Copyright NordicNeuroLab AS 2021 %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%% File:          analyzeDataMRC.m
%% Init Author:   ”Carl Fredrik Haakonsen” <cfhaakonsen@gmail.com>
%% Init Date:     2021-08-12
%% Project:       Eye tracking testing
%% Description:   Script analyzing the gaze tracking data from MRC after
%%                using the test script "gridTest.m".
%%
%% To run this script you must first collect gaze tracking data from MRC 
%% when running the Psychtoolbox test script gridTest.m. For proper alignment 
%% of the data the MRC stimuli window must be set properly. This is because
%% the stimuli window size also determines how much of the screen is included
%% in the calibration, which must be limited. Use the following parameters
%% for the window with this script:
%% [Position x, Position y, Width, Height] = [376, 149, 1153, 841]

%% Further the filenames needs to be set in the scripts. The names
%% from both "testGrid.m" and MRC must then be entered in the variables
%% "gtFilename" (from testGrid.m) and "gazeFilename" (from MRC). MRC will save 
%% the data from each eye in separate files. Choose therefore the filename
%% of the eye you want to analyze data from. Finally the column numbers of the 
%% desired gaze data must be specified in "gazeColX". Open the data file to 
%% see which columns containing which data. 
%%
%% The script will show a plot of the recorded gaze data along with the 
%% ground truths from "testGrid.m". The plot will also show a line from the
%% point to the mean of the gaze points to indicate the accuracy. The test 
%% script shows a grid of points the subject should fixate on one-by-one. 
%% Note that if MRC looses track of the pupil or glint, no gaze data will be
%% given. This may result in no data recorded for some points. If this happens
%% the plot legend will be affected too, but all the plotted data are correct. 
%% AS FOR NOW THE PLOT IS UPSIDE DOWN RELATIVE TO THE COMPUTER MONITOR. THE 
%% DATA IS IN COMPUTER COORDINATES WHICH IS NOT ACCOUNTED FOR. 
%% As well as plotting the data, some performance metrics are calcuated. 
%% For each point the following metrics are calculated:
%%
%%  - Mean: x and y coordinates
%%  - Accuracy: Measured as the average of the distances from gaze points to gt. 
%%    Accuracy for x and y are given separately in pixels. Total relative 
%%    accuracy is also given in degrees. 
%%  - Precision: Measured as the standard deviation. Std given for x and y 
%%    seperately as well as the total relative std in degrees.
%%  - Inter measurement RMS: Given seperately for x and y, as well as total 
%%    relative inter measurement RMS in degrees. 
%%
%% The data above are stored in the cell "gaze_data". Each row in the cell
%% contains data for the test point number corresponding to the row number.
%% The raw gaze data is saved here as well. This data is time gated, meaning
%% it is the gaze data from when the subject was fixating at this point.
%% One row has the following structure:
%%
%% Data:       Raw gaze data     Mean     Accuracy      Precision    IM-RMS
%% Structure:  2xNumPoints of    [x; y]   [x; y; deg]   [x; y; deg]  [x; y; deg]
%%             x,y coordinates
%%
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Clearing the workspace
clearvars;

% -----------------------------------------------------------------------------
%                            SETUP PARAMETERS
% -----------------------------------------------------------------------------

% Name og the input files. The .csv file is the output from the Psychtoolbox
% test scripts, while the .trk is the MRC data file.
gt_data = csvread('DemoData3_gridTest.csv');
filename = 'DemoData3_MRC_Camera1.trk';

% Offset for the MRC data. MRC will give the data in coordinates relative to the
% stimuli window. An offset is therefore needed as the MRC window can not be
% full screen to get a good calibration. The offset is also due to MRC being
% buggy. This offset corresponds to the following parameters for the MRC
% stimuli window: 
% [Position x, Position y, Width, Height] = [376, 149, 1153, 841]
% These values will center the window in the VSHD display and cover
% respectively 60% and 70% of the screens width and height. 
mrcOffset_x = 384;
mrcOffset_y = 180;

% The columns containing the gaze data. 
gazeColX = 8;
gazeColY = gazeColX + 1;

% Set the screen dimensions
screenHeight = 1200;
screenWidth = 1920;

% -----------------------------------------------------------------------------
%                          READING DATA FROM FILES
% -----------------------------------------------------------------------------

% Read the data as strings, or else it stops reading when it is not a number.
fid = fopen(filename, 'r');
data = textscan(fid, '%q%q%q%q%q%q%q%q%q%q%q%q', 'HeaderLines', 4, 'CollectOutput' ,1);
fclose(fid);

% Covert the data to a matrix of floats
data = cell2mat(data);
data = str2double(data);

% Get the start time
fid = fopen(filename, 'r');
startTimeInfo = fgetl(fid);
fclose(fid);

% Get the starttime 
startTimeInfo = strsplit(startTimeInfo);
startTimeCounter = str2double(startTimeInfo(1,3));

% -----------------------------------------------------------------------------
%                      CONVERTING DATA TO PROPER FORMATS
% -----------------------------------------------------------------------------

% Convert to dateVector
startTime = cell2mat(startTimeInfo(1,5));
year = str2double(startTime(1:4));
month = str2double(startTime(6:7));
day = str2double(startTime(9:10));
hour = str2double(startTime(12:13));
minute = str2double(startTime(15:16));
seconds = str2double(startTime(18:23));

dateVector = [year, month, day, hour, minute, seconds];
dateNum = datenum(dateVector);

epochTime = (dateNum - 719529)*86400 - 2*60*60;
ctime(epochTime);

% Convert all time stamps to epoch time
data(:, 1) = epochTime + (data(:, 1) - startTimeCounter)/1000;

% Extract only the useful data
data = data(:, [1, gazeColX, gazeColY]);

% Adding the offset to the data
data(:, 2) = data(:, 2) + mrcOffset_x;
data(:, 3) = data(:, 3) + mrcOffset_y;

% Initialize a cell for storing information serarately for each test point
gaze_data = cell(size(gt_data, 1), 1);

% Save the data for each "calibration" point in separate cells in point_data.
% Each row in point_data contains information about the point corresponding to the row number. 
for i = 1 : size(data, 1)
  for j = 1 : size(gt_data, 1)
     if data(i, 1) > gt_data(j, 3) && data(i, 1) < gt_data(j, 4)
       if ~isnan(data(i,2))
         gaze_data{j} = [gaze_data{j} [data(i, 2); data(i, 3)]];
       end
     end
   end
end

% -----------------------------------------------------------------------------
%                     CALCULATING METRICS AND PLOTTING DATA
% -----------------------------------------------------------------------------

% List of marker commands for different styles for different points in the plot
markers = {'+','o','*','x','v','d','^','s','>','<'};

% Plotting the gaze points and calculating metrics
for i = 1 : size(gt_data, 1)
  if ~isempty(gaze_data{i})
    % Plotting all the gaze data corresponing to one "calibration/test" point
    scatter(gaze_data{i}(1,:), gaze_data{i}(2,:), 10, markers(i)); hold on;
    
    % Calculating the mean for each of the points and adding it to the second 
    % cell column in gaze_data
    gaze_data{i, 2} = mean(gaze_data{i, 1}, 2);
    
    if size(gaze_data{i}, 2) > 1
      % Calculating accuracy as average distance between true and estimated 
      % gaze point and adding to third column in gaze_data cell. Done both for
      % x, y and total relative error in degrees. 
      avgDist_x_y = mean ( abs( gaze_data{i} - gt_data(i, 1:2)' ) , 2);
      gaze_data{i,3} = [avgDist_x_y; pix2deg(avgDist_x_y(1), avgDist_x_y(2)) ]; 
      
      % Calculating standard deviation in x and y directions, and adding 
      % to fourth column in gaze_data cell. Done both for x, y and total
      % relative standard deviation in degrees. 
      point_std_xy = std(gaze_data{i}', 1)';
      gaze_data{i,4} = [point_std_xy; pix2deg( point_std_xy(1), point_std_xy(2) )];
      
      % Calculating inter-measurement RMS and adding it to fifth column in 
      % the gaze_data cell. Done both for x, y and total relative IM-RMS in degrees.
      % "inter_diff_xy" is the difference between point i and i+1.
      inter_diff_xy = gaze_data{i}(:, 2:end) - gaze_data{i}(:, 1:end-1); 
      inter_RMS_xy = sqrt( mean( inter_diff_xy.^2, 2 ) );
      gaze_data{i,5} = [inter_RMS_xy; pix2deg( inter_RMS_xy(1), inter_RMS_xy(2) )];
    end
  end
end

% Plotting lines indicating position to the means of the estimated points
for i = 1 : size(gt_data, 1)
  if ~isempty(gaze_data{i})
    plot([gaze_data{i,2}(1) gt_data(i,1)], [gaze_data{i,2}(2) gt_data(i,2)], 'r'); hold on;
    scatter(gaze_data{i,2}(1), gaze_data{i,2}(2), 20, 'r', 'o'); hold on;
  end
end

% Plotting all the true gaze positions. 
scatter(gt_data(:,1), gt_data(:,2), 80, 'r', 'x');
set(gca, "linewidth", 2, "fontsize", 30);

% Adding legend and limiting plot
legend('1', '2', '3', '4', '5', '6', '7', '8', '9');
xlim([0 screenWidth]); ylim([0 screenHeight]);
hold off;
