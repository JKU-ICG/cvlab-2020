% --------------- Example How to Load and Work with RGB+thermal data ------
clear all; clc; close all; % clean up!

%%

% TOP row:
rgbpath = './data/peaches/top/RGB';
thermalpath = './data/peaches/top/thermal'; 

% BOTTOM row:
rgbpath = './data/peaches/bottom/RGB';
thermalpath = './data/peaches/bottom/thermal'; 

rgbds = datastore( rgbpath );
thermalds = datastore( thermalpath );
assert( length(rgbds.Files) == length(thermalds.Files) );
% Note: RGB-thermal pairs are paired by the sorted filename!
% (e.g., the first image in the RGB folder corresponds to the first image
% in the thermal folder)

%% display pairs (without any modifications)
for i = 1:length(rgbds.Files)
    rgb = readimage( rgbds, i );
    thermal = readimage( thermalds, i );
    
    figure(i); clf;
    subplot(2,1,1); imshow( rgb ); title( 'RGB' );
    subplot(2,1,2); imshow( thermal, [] ); title ( 'thermal' );
    % show with colormap:  colormap( 'parula' );
    drawnow; % display immediately
    
end


%% display undistored pairs
rgbParams = load( './data/camParams_RGB.mat' );
thermalParams = load( './data/camParams_thermal.mat' );

for i = 1; % for all use 1:length(rgbds.Files)
    rgb = undistortImage( readimage( rgbds, i ), rgbParams.cameraParams );
    thermal = undistortImage( readimage( thermalds, i ), thermalParams.cameraParams );
    
    figure(i); clf;
    subplot(2,1,1); imshow( rgb ); title( 'RGB' );
    subplot(2,1,2); imshow( thermal, [] );  title ( 'thermal' );
    colormap( 'parula' );
    drawnow; % display immediately
    
end

%% naively overlay rgb on thermal images
i = 1; % index
h_fig = figure(i); clf;
thermal = undistortImage( readimage( thermalds, i ), thermalParams.cameraParams );
rgb = undistortImage( readimage( rgbds, i ), rgbParams.cameraParams );
rgb = imresize( rgb, size(thermal) );
imshowpair( rgb, thermal, 'falsecolor' );


%% overlay thermal and rgb images with intrinsics

% we need a transformation to map RGB images to thermal
% multiplying the inverse RGB intrinsic and the thermal intrinsics is
% results in the proper transformation.
M = inv(rgbParams.cameraParams.IntrinsicMatrix) * thermalParams.cameraParams.IntrinsicMatrix;
tform = projective2d( M );

for i = 1; % for all use 1:length(rgbds.Files)
    thermal = undistortImage( readimage( thermalds, i ), thermalParams.cameraParams );
    rgb = undistortImage( readimage( rgbds, i ), rgbParams.cameraParams );
    rgb = imwarp(rgb,tform,'OutputView',imref2d(size(thermal))); %warp RGB
    [~,rgbfileinfo] = readimage( rgbds, i );
    [~,thermalfileinfo] = readimage( thermalds, i );
    
    [~,rgbname,~] = fileparts(rgbfileinfo.Filename);
    [~,thermalname,~] = fileparts(thermalfileinfo.Filename);
    
    h_fig = figure(i); clf;
    set( h_fig, 'Name', [ 'RGB:' rgbname ', thermal:' thermalname ] );
    imshowpair( rgb, thermal, 'falsecolor' );
    drawnow; % display immediately
    
end

%% calibrate mapping of RGB<->thermal with checkerboard

% CALIBRATION:
calibrgbpath = './data/peaches/calibration/RGB';
calibthermalpath = './data/peaches/calibration/thermal';
calibrgbds = datastore( calibrgbpath );
calibthermalds = datastore( calibthermalpath );

usePatternId = 1;

rgb = undistortImage( readimage( calibrgbds, usePatternId ), rgbParams.cameraParams );
[rgb_imagePoints,rgb_boardSize,rgb_imagesUsed] = detectCheckerboardPoints(rgb);
thermal = undistortImage(readimage( calibthermalds, usePatternId ), thermalParams.cameraParams );
thermal = 255 - thermal; % invert so that it matches the RGB colors
[thermal_imagePoints,thermal_boardSize,thermal_imagesUsed] = detectCheckerboardPoints(thermal);
assert( isequal( thermal_boardSize, rgb_boardSize ) );

figure(100); clf;
subplot(2,2,1); imshow( rgb ); title( 'RGB' ); hold on;
plot( rgb_imagePoints(:,1), rgb_imagePoints(:,2), 'rx' );
subplot(2,2,2); imshow( thermal, [] );  title ( 'thermal' ); hold on;
plot( thermal_imagePoints(:,1), thermal_imagePoints(:,2), 'rx' );


%% estimate 2D transformation (for imwarp)
tform = fitgeotrans(rgb_imagePoints,thermal_imagePoints,'projective');

% --- warp images ---
% rgb on thermal
warpedrgb = imwarp(rgb,tform,'OutputView',imref2d(size(thermal)));
% thermal on RGB
warpedthermal = imwarp(thermal,tform.invert(),'OutputView',imref2d(size(rgb)));

figure(100); % continue figure ...
subplot(2,2,3); imshow( warpedthermal ); title( 'warped thermal' ); hold on;
plot( rgb_imagePoints(:,1), rgb_imagePoints(:,2), 'rx' );
subplot(2,2,4); imshow( warpedrgb );  title ( 'warped RGB' ); hold on;
plot( thermal_imagePoints(:,1), thermal_imagePoints(:,2), 'rx' );


figure(101);
subplot(1,2,1); title ( 'warped thermal to RGB' ); 
imshowpair( rgb, warpedthermal, 'falsecolor' ); title( 'original RGB, warped thermal' );
subplot(1,2,2); title ( 'RGB to warped thermal' ); 
imshowpair( warpedrgb, thermal, 'falsecolor' );  title( 'original thermal, warped RGB' );

%% estimate extrinsics too 

squareSize = 50;  % 'millimeters'
worldPoints = generateCheckerboardPoints(thermal_boardSize, squareSize);

[thermal_rotation,thermal_transl] = extrinsics(thermal_imagePoints,worldPoints,thermalParams.cameraParams);
[rgb_rotation, rgb_transl] = extrinsics(rgb_imagePoints,worldPoints,rgbParams.cameraParams);

% relative transformation (rotation + translation) from RGB to thermal
R = rgb_rotation' * thermal_rotation;
t = thermal_transl - rgb_transl * R;
% save:
if ~exist( 'results', 'dir' ), mkdir( 'results' ); end;
save( './results/rgb2thermal_transf.mat', 'R', 't' );

worldPoints3D = worldPoints;
worldPoints3D(:,3) = 0;
% reproject thermal
thermal_reproj = worldToImage( thermalParams.cameraParams, thermal_rotation, thermal_transl, worldPoints3D );
% reproject on thermal with RGB rotation and translation

% reproject RGB
rgb_reproj = worldToImage( rgbParams.cameraParams, rgb_rotation, rgb_transl, worldPoints3D );
% reproject on RGB with thermal transformations
thermal2rgb_reproj = worldToImage( rgbParams.cameraParams, thermal_rotation*R', (thermal_transl-t)*R', worldPoints3D );



figure(102);
subplot(1,2,1); imshow( thermal );  title ( 'thermal' ); hold on;
plot( thermal_reproj(:,1), thermal_reproj(:,2), 'r+' );
plot( rgb2thermal_reproj(:,1), rgb2thermal_reproj(:,2), 'gx' );
subplot(1,2,2); imshow( rgb );  title ( 'RGB' ); hold on;
plot( rgb_reproj(:,1), rgb_reproj(:,2), 'r+' );
plot( thermal2rgb_reproj(:,1), thermal2rgb_reproj(:,2), 'gx' );

