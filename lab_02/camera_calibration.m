% --- Computer Vision Toolbox: Camera Calibration ---
clear; close all; clc; % clean up!
% for details see: https://de.mathworks.com/videos/camera-calibration-with-matlab-81233.html
% -------------------------------------------------------------------------


% RGB images:
% DOWNLOAD from: https://drive.google.com/open?id=1sn5okDv9zIt2ieGDdhi8-QqPwrsDI4-P
% NOTE: images are quite large and thus calibration takes time
% imgData = imageDatastore( fullfile( 'data/calibration/RGB/' ) );

% thermal images: (lower resolution)
imgData = imageDatastore( fullfile( './data/calibration/thermal/' ) );
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


% View reprojection errors
h1=figure(1); showReprojectionErrors(cameraParams);

% Visualize pattern locations
h2=figure(2); showExtrinsics(cameraParams, 'CameraCentric');

% Display parameter estimation errors
displayErrors(estimationErrors, cameraParams);

% Store for later usage:
if ~exist( 'results', 'dir' ), mkdir( 'results' ); end;
if ~isempty(strfind( imgData.Files{1}, 'RGB' ))
    save( 'results/camParams_RGB.mat', 'cameraParams', 'imageFileNames', 'estimationErrors' );
elseif ~isempty(strfind( imgData.Files{1}, 'thermal' ))
    save( 'results/camParams_thermal.mat', 'cameraParams', 'imageFileNames', 'estimationErrors' );
end

%% For example, you can use the calibration data to remove effects of lens distortion.
undistortedImage = undistortImage(originalImage, cameraParams);
figure(3); subplot(1,2,1); imshow( originalImage ); title( 'original' );
subplot(1,2,2); imshow( undistortedImage ); title( 'undistored' );

%% Project 3D points on checkerboard

worldPts3D = worldPoints; % cornerpoints of the checkerboard
worldPts3D(:,3) = 0; % add z axis with 0

useId = 8; % pick an image to project to
rotMatrix = cameraParams.RotationMatrices(:,:,useId); % 3x3 matrix
translVector = cameraParams.TranslationVectors(useId,:); %1x3 vector

I = imread(imageFileNames{useId});
U = undistortImage(I, cameraParams);

% reproject 3D points onto image
imgPtsU = worldToImage(cameraParams,rotMatrix,translVector,worldPts3D,'ApplyDistortion',false);
imgPtsI = worldToImage(cameraParams,rotMatrix,translVector,worldPts3D,'ApplyDistortion',true);

figure(4); 
subplot(1,2,1); imshow( I ); title( 'reproject on original (with distortions)' ); hold on;
% also show detected corners in pixels (by detectCheckerboardPoints): 
%   plot( imagePoints(:,1,useId), imagePoints(:,2,useId), 'r+', 'MarkerSize', 20, 'LineWidth', 3 );
plot( imgPtsI(:,1), imgPtsI(:,2), 'bx', 'MarkerSize', 20, 'LineWidth', 3 );
subplot(1,2,2); imshow( U ); title( 'reproject on undistored' ); hold on;
plot( imgPtsU(:,1), imgPtsU(:,2), 'bx', 'MarkerSize', 20, 'LineWidth', 3 );

%% manually project 3D points onto image (without worldToImage function)

% bring into camera coordinate system
camPts = worldPts3D * rotMatrix + translVector;

K = cameraParams.IntrinsicMatrix; % intrinsic camera matrix

% project with intrinsic camera matrix
tmpPts = camPts * K;
imgPts = tmpPts(:,1:2) ./ tmpPts(:,3); % perspective division


figure(5); 
imshow( U ); title( 'manual reproject on undistored' ); hold on;
plot( imgPts(:,1), imgPts(:,2), 'g+', 'MarkerSize', 20, 'LineWidth', 3 );





