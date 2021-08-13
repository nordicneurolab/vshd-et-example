%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%% Copyright NordicNeuroLab AS 2021 %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%% File:          pix2deg.m
%% Init Author:   ”Carl Fredrik Haakonsen” <cfhaakonsen@gmail.com>
%% Init Date:     2021-08-12
%% Project:       Eye tracking testing
%% Description:   Script containing function that converts error in pixels to
%%                degrees. 
%%
%% The function is called from the scripts "analyzeDataArrington.m" and
%% "analyzeDataMRC.m". The FOV depends on the diopter setting and can be 
%% changed here. 
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function deg = pix2deg(pix_error_x, pix_error_y)
  % VSHD screen resolution
  h_res = 1920;
  v_res = 1200;
  
  % VSHD Field of View
  h_fov = 50; 
  v_fov = 30;
  
  % Calculate relative error distance in degrees. Not accounting for distortion. 
  deg = sqrt( (pix_error_x/( h_res/h_fov ))**2 + (pix_error_y/( v_res/v_fov ))**2);
end