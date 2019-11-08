% --------------- Dense Structure From Motion Precomputed ------------------------
clear all; clc; close all; % clean up!

%% load the camera parameters:
data = load(fullfile('./data/camParams_RGB.mat'));
cameraParams = data.cameraParams;

% Get intrinsic parameters of the camera
intrinsics = cameraParams.Intrinsics;

%% load reconstruction

% TOP
load('./data/sfm_top.mat');
rgbpath = './data/peaches/top/RGB/';
thermalpath = './data/peaches/top/thermal'; 


% BOTTOM row:
% load('./data/sfm_bottom.mat');
% rgbpath = './data/peaches/bottom/RGB';
% thermalpath = './data/peaches/bottom/thermal'; 

rgbds = datastore( rgbpath );
thermalds = datastore( thermalpath );
assert( length(rgbds.Files) == length(thermalds.Files) );


%%
camPoses = poses(vSet);
figure(1); clf; 
plotCamera(camPoses, 'Size', 0.2); title( 'precomputed reconstruction' );
hold on

% Display the 3-D points.
pcshow(xyzPoints, rgbPoints, 'VerticalAxis', 'y', 'VerticalAxisDir', 'up', ...
    'MarkerSize', 45);

% Specify the viewing volume.
loc1 = camPoses.Location{5};
xlim([loc1(1)-10, loc1(1)+10]);
ylim([loc1(2)-10, loc1(2)+10]);
zlim([loc1(3)-1, loc1(3)+50]);
camorbit(0, -30);





%% reproject the points into an image
useId = 12; % 1 to numImagesToLoad;

loc = camPoses.Location{useId};
ori = camPoses.Orientation{useId};
[rot, transl] = cameraPoseToExtrinsics( ori, loc );

reprojPoints = worldToImage( cameraParams, rot, transl, xyzPoints );

I = imread( fullfile( rgbpath, imagenames{useId} ) );
I = undistortImage( I, cameraParams );

figure(2); clf; 
imshow( I ); hold on; title( 'reproject precomputed RGB points' );
%plot( reprojPoints(:,1), reprojPoints(:,2), 'k.' );
scatter( reprojPoints(:,1), reprojPoints(:,2), 1, double(rgbPoints)./255, 'filled' );
drawnow;



%% reproject onto thermal
r2t = load( './results/rgb2thermal_transf.mat' );
r2t.t = r2t.t * 0.0025; % scaling needs to be adjustet because there is no checkerboard for reference in this scene!
thermalParams = load( './data/camParams_thermal.mat' );
% Note: this needs the peaches_data.m script to be run first!

% just a quick check if pairing is correct!
[filepath,name,ext] = fileparts(rgbds.Files{useId});
assert( isequal(imagenames{useId},[name,ext]) );

rgb2thermal_reproj = worldToImage( thermalParams.cameraParams, rot*r2t.R, transl*r2t.R+r2t.t, xyzPoints );

% display
T = readimage( thermalds, useId );
T = undistortImage( T, thermalParams.cameraParams );
figure(3); clf; 
imshow( T, [] ); hold on; title( 'reproject RGB points onto thermal' );
scatter( rgb2thermal_reproj(:,1), rgb2thermal_reproj(:,2), 1, double(rgbPoints)./255, 'filled' );
drawnow;

%% display reprojection pairs (takes some time)
return; % script stops here! 

for useId = 1:length(rgbds.Files)
    
    % camera pose
    loc = camPoses.Location{useId};
    ori = camPoses.Orientation{useId};
    rot = ori'; % rotation
    transl = -loc*rot; % translation
    
    % RGB:
    I = imread( fullfile( rgbpath, imagenames{useId} ) );
    I = undistortImage( I, cameraParams );
    reprojPoints = worldToImage( newCamParams, rot, transl, xyzPoints );

    
    % make sure that pairs are correct!
    [filepath,name,ext] = fileparts(rgbds.Files{useId});
    assert( isequal(imagenames{useId},[name,ext]) );
    
    % thermal:
    T = readimage( thermalds, useId );
    T = undistortImage( T, thermalParams.cameraParams );
    rgb2thermal_reproj = worldToImage( thermalParams.cameraParams, rot*r2t.R, transl*r2t.R+r2t.t, xyzPoints );


    fig=figure(10+useId); clf(fig,'reset');
    subplot(1,2,1); hold off;
    imshow( I ); hold on;
    %plot( reprojPoints(:,1), reprojPoints(:,2), 'k.' );
    scatter( reprojPoints(:,1), reprojPoints(:,2), 1, double(rgbPoints)./255, 'filled' );
    subplot(1,2,2); hold off;
    imshow( T, [] ); hold on;
    colormap( 'parula' );
    %plot( rgb2thermal_reproj(:,1), rgb2thermal_reproj(:,2), 'k.' );
    scatter( rgb2thermal_reproj(:,1), rgb2thermal_reproj(:,2), 1, double(rgbPoints)./255, 'filled' );
    drawnow;
    



end



