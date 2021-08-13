%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%% Copyright NordicNeuroLab AS 2021 %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%% File:          analyzeDataArrington.m
%% Init Author:   ”Carl Fredrik Haakonsen” <cfhaakonsen@gmail.com>
%% Init Date:     2021-08-12
%% Project:       Eye tracking testing
%% Description:   Script analyzing the gaze tracking data from Arrington after
%%                using the test script "gridTest.m".
%%
%% To run this script you must first collect gaze tracking data from Arrington 
%% when running the Psychtoolbox test script gridTest.m. The output filenames
%% from both "testGrid.m" and Arrington must then be entered in the variables
%% "gtFilename" (from testGrid.m) and "gazeFilename" (from Arrington). Then the
%% variable "binocular"  must be changed accordingly to what data has been
%% recorded. Finally the column numbers of the desired gaze data must be
%% specified in "gazeColX". Open the data file to see which columns containing
%% which data. 
%%
%% The script will show a plot of the recorded gaze data along with the 
%% ground truths from "testGrid.m". The plot will also show a line from the
%% point to the mean of the gaze points to indicate the accuracy. The test 
%% script shows a grid of points the subject should fixate on one-by-one. 
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

% Clear the workspace
clearvars;

% -----------------------------------------------------------------------------
%                            SETUP PARAMETERS
% -----------------------------------------------------------------------------

% Name og the input files. The .csv file is the output from the Psychtoolbox
% test scripts, while the .txt is the Arrington data file.
gtFilename = 'DemoData2_gridTest.csv';
gazeFilename = 'DemoData2_ArringtonBinocular.txt';

% Choose if the data file is for monocular or binocular. This will affect the
% number of columns in the file as well as the size of the header file. 
% 1 = binocular, 0 = monocular.
binocular = 1;

% Choose the column numbers corresponding to the desired gaze data in the 
% data file. Can be corrected and raw gaze data. 
gazeColX = 6;
gazeColY = gazeColX + 1;

% Set the VSHD screen dimensions
screenHeight = 1200;
screenWidth = 1920;

% -----------------------------------------------------------------------------
%                          READING DATA FROM FILES
% -----------------------------------------------------------------------------

% Read the ground truth data containing gt points and start and stop times
gt_data = csvread(gtFilename);

% Setting the parameters for reading of the data file. Depends on monocular
% and binocular
if binocular
  numCols = 27;
  headerRows = 44;
else
  numCols = 13;
  headerRows = 40;
end

% Read the data
fid = fopen(gazeFilename);
data = textscan(fid, repmat('%f', 1, numCols), 'HeaderLines', headerRows, 'CollectOutput' ,1);
fclose(fid);

% Get the start time, which is only given in seconds arrington(?)
fid = fopen(gazeFilename, 'r');
linenum = 8;
startTimeInfo = textscan(fid,'%s',1,'delimiter','\n', 'headerlines', linenum-1);
fclose(fid);

% Convert the data to matrices
data = cell2mat(data);
startTimeInfo = strsplit(cell2mat(startTimeInfo{1}));
startTimeInfo = str2double(startTimeInfo(3:8));
startTimeInfo(4) = startTimeInfo(4) + 2; % Add two hours to get the right time

% Extract only the usefull information, which is timestamps 
% plus x and y coordinate
data = data(:, [2, gazeColX, gazeColY]);

% -----------------------------------------------------------------------------
%                      CONVERTING DATA TO PROPER FORMATS
% -----------------------------------------------------------------------------

% Convert the start time to epoch time, which is the same as 
% the gt data timestamps
dateNum = datenum(startTimeInfo);
epochTime = (dateNum - 719529)*86400 - 2*60*60;

% Convert the timestamps to epoch time, and convert the cooridnates to pixels.
data(:, 1) = data(:, 1) + epochTime;
data(:, 2) = data(:, 2) * screenWidth;
data(:, 3) = data(:, 3) * screenHeight;

% Initialize a cell for storing information serarately for each test point
gaze_data = cell(size(gt_data, 1), 1);

% Save the data for each "calibration" point in separate cells in point_data.
% Each row in gaze_data contains information about the point 
% corresponding to the row number. 
for i = 1 : size(data, 1)
  for j = 1 : size(gt_data, 1)
     if data(i, 1) > gt_data(j, 3) && data(i, 1) < gt_data(j, 4)
       gaze_data{j} = [gaze_data{j} [data(i, 2); data(i, 3)]];
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
  % Plotting all the gaze data corresponing to one "calibration/test" point
  scatter(gaze_data{i}(1,:), gaze_data{i}(2,:), 10, markers(i)); hold on;
  
  % Calculating the mean for each of the points and adding it to the second 
  % cell column in gaze_data
  gaze_data{i, 2} = mean(gaze_data{i, 1}, 2);
  
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

% Plotting lines indicating position to the means of the estimated points
for i = 1 : size(gt_data, 1)
  plot([gaze_data{i,2}(1) gt_data(i,1)], [gaze_data{i,2}(2) gt_data(i,2)], 'r'); hold on;
  scatter(gaze_data{i,2}(1), gaze_data{i,2}(2), 20, 'r', 'o'); hold on;
end

% Plotting all the true gaze positions. 
scatter(gt_data(:,1), gt_data(:,2), 80, 'r', 'x');
set(gca, "linewidth", 2, "fontsize", 30);

% Adding legend and limiting plot
legend('1', '2', '3', '4', '5', '6', '7', '8', '9');
xlim([0 screenWidth]); ylim([0 screenHeight]);
hold off;
