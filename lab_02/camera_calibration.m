% --- Computer Vision Toolbox: Camera Calibration ---
clear; close all; clc; % clean up!
% for details see: https://de.mathworks.com/videos/camera-calibration-with-matlab-81233.html
% -------------------------------------------------------------------------


% Define images to process
imgData = imageDatastore( fullfile( '../data/calibration/RGB/' ) );
%imgData = imageDatastore( fullfile( '../data/calibration/thermal/' ) );
imageFileNames = imgData.Files;


% Detect checkerboards in images
[imagePoints, boardSize, imagesUsed] = detectCheckerboardPoints(imageFileNames);
imageFileNames = imageFileNames(imagesUsed);

if ~isempty(strfind( imgData.Files{1}, 'thermal' ))
    % flip origin (only for thermal)
    imagePoints(end:-1:1,:,:) = imagePoints;
end

% Read the first image to obtain image size
originalImage = imread(imageFileNames{1});
[mrows, ncols, ~] = size(originalImage);

% Generate world coordinates of the corners of the squares
squareSize = 50;  % in units of 'millimeters'
worldPoints = generateCheckerboardPoints(boardSize, squareSize);

% Calibrate the camera 
[cameraParams, imagesUsed, estimationErrors] = estimateCameraParameters(imagePoints, worldPoints, ...
    'EstimateSkew', false, 'EstimateTangentialDistortion', false, ...
    'NumRadialDistortionCoefficients', 2, 'WorldUnits', 'millimeters', ...
    'InitialIntrinsicMatrix', [], 'InitialRadialDistortion', [], ...
    'ImageSize', [mrows, ncols]);
% % Calibrate the camera ADVANCED (more parameters)
% [cameraParams, imagesUsed, estimationErrors] = estimateCameraParameters(imagePoints, worldPoints, ...
%     'EstimateSkew', false, 'EstimateTangentialDistortion', true, ...
%     'NumRadialDistortionCoefficients', 2, 'WorldUnits', 'millimeters', ...
%     'InitialIntrinsicMatrix', [], 'InitialRadialDistortion', [], ...
%     'ImageSize', [mrows, ncols]);


% View reprojection errors
h1=figure; showReprojectionErrors(cameraParams);

% Visualize pattern locations
h2=figure; showExtrinsics(cameraParams, 'CameraCentric');

% Display parameter estimation errors
displayErrors(estimationErrors, cameraParams);

% Store for later usage:
if ~isempty(strfind( imgData.Files{1}, 'RGB' ))
    save( 'camParams_RGB.mat', 'cameraParams', 'imageFileNames', 'estimationErrors' );
elseif ~isempty(strfind( imgData.Files{1}, 'thermal' ))
    save( 'camParams_thermal.mat', 'cameraParams', 'imageFileNames', 'estimationErrors' );
end

% For example, you can use the calibration data to remove effects of lens distortion.
undistortedImage = undistortImage(originalImage, cameraParams);
