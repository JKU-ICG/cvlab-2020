% --------------- Structure From Motion Example ------------------------
clear all; clc; close all; % clean up!
% based on: https://de.mathworks.com/help/vision/examples/structure-from-motion-from-multiple-views.html

% read all images in a folder
rgbFolder = './data/peaches/top/RGB/';
dirlist = dir(fullfile(rgbFolder,'*.JPG'));
imagelist = {dirlist.name};


imgscale = .25; % scale images so that processing is faster
numImagesToLoad = 6; % only work on a subset of images

%% load the camera parameters:
data = load(fullfile('./data/camParams_RGB.mat'));
cameraParams = data.cameraParams;

% Get intrinsic parameters of the camera
intrinsics = cameraParams.Intrinsics;

% rescale intrinsic matrix if images are resized
intrinsics = cameraIntrinsics(intrinsics.FocalLength*imgscale,intrinsics.PrincipalPoint*imgscale,intrinsics.ImageSize*imgscale);

%% load images (resize and undistort them)
images = cell(1, numImagesToLoad );
imgcount = 1;
for i = numel(imagelist):-1:(numel(imagelist)-numImagesToLoad+1)
    images{imgcount} = imread(fullfile(rgbFolder,imagelist{i}));
    if imgscale ~= 1
        images{imgcount} = imresize( images{imgcount}, imgscale );
    end
    % undistort
    images{imgcount} =  undistortImage(images{imgcount}, intrinsics); 

    imgcount = imgcount + 1; % increase counter
end




%% convert images to grayscale for SURF feature processing
greys = cell(1, numel(images));
for i = 1:numel(images)
    greys{i} = rgb2gray(images{i});
end

%% create a datastructure with the first view for SFM
I =  greys{1}; 

NumOctaves = 3; % for SURF
NumScaleLevels = 8;
Upright = true;
MetricThreshold = 200;


% Detect features. Increasing 'NumOctaves' helps detect large-scale
% features in high-resolution images. Use an ROI to eliminate spurious
% features around the edges of the image.
border = 50;
roi = [border, 4*border, size(I, 2)- 2*border, size(I, 1)- 5*border]; % add more border at the top to ignore rotors of the drone
prevPoints   = detectSURFFeatures(I, 'NumOctaves', NumOctaves, 'NumScaleLevels', NumScaleLevels, 'ROI', roi, 'MetricThreshold', MetricThreshold);

% Extract features. Using 'Upright' features improves matching, as long as
% the camera motion involves little or no in-plane rotation.
prevFeatures = extractFeatures(I, prevPoints, 'Upright', Upright);

% Create an empty viewSet object to manage the data associated with each
% view.
vSet = viewSet;

% Add the first view. Place the camera associated with the first view
% and the origin, oriented along the Z-axis.
viewId = 1;
vSet = addView(vSet, viewId, 'Points', prevPoints, 'Orientation', ...
    eye(3, 'like', prevPoints.Location), 'Location', ...
    zeros(1, 3, 'like', prevPoints.Location));

prevI = I;


%% continue with other views 
for i = 2:numel(images)
    % Undistort the current image.
    I = greys{i};
    
    % Detect, extract and match features.
    currPoints   = detectSURFFeatures(I, 'NumOctaves', NumOctaves, 'NumScaleLevels', NumScaleLevels, 'ROI', roi, 'MetricThreshold', MetricThreshold);
    currFeatures = extractFeatures(I, currPoints, 'Upright', Upright);    
    indexPairs = matchFeatures(prevFeatures, currFeatures, ...
        'MaxRatio', .6, 'Unique',  false);
    
    % Select matched points.
    matchedPointsPrev = prevPoints(indexPairs(:, 1));
    matchedPointsCurr = currPoints(indexPairs(:, 2));
    
    % Display matches:
    figure(1); clf;
    showMatchedFeatures(prevI, I, matchedPointsPrev, matchedPointsCurr, 'montage');
    title('Matched Features');
    drawnow;
    
    % Estimate the camera pose of current view relative to the previous view.
    % The pose is computed up to scale, meaning that the distance between
    % the cameras in the previous view and the current view is set to 1.
    % This will be corrected by the bundle adjustment.
    try
        [relativeOrient, relativeLoc, inlierIdx] = helperEstimateRelativePose(...
            matchedPointsPrev, matchedPointsCurr, intrinsics);
    catch
        % if it does not run with the default parameters reduce the quality settings
        % and re-run helperEstimateRelivatePose ...
        [relativeOrient, relativeLoc, inlierIdx] = helperEstimateRelativePose(...
            matchedPointsPrev, matchedPointsCurr, intrinsics, 0.5, 10, 1000 );
    end
    
    % Find epipolar inliers
    inlierPoints1 = prevPoints(indexPairs(inlierIdx,1));
    inlierPoints2 = currPoints(indexPairs(inlierIdx,2));

    % Display inlier matches
    figure(1); clf;
    showMatchedFeatures(prevI, I, inlierPoints1, inlierPoints2, 'montage');
    title('Inlier Features');
    drawnow;

    
    % Add the current view to the view set.
    viewId = viewId + 1;
    vSet = addView(vSet, viewId, 'Points', currPoints);
    
    % Store the point matches between the previous and the current views.
    vSet = addConnection(vSet, viewId-1, viewId, 'Matches', indexPairs(inlierIdx,:));
    
    % Get the table containing the previous camera pose.
    prevPose = poses(vSet, viewId-1);
    prevOrientation = prevPose.Orientation{1};
    prevLocation    = prevPose.Location{1};
        
    % Compute the current camera pose in the global coordinate system 
    % relative to the first view.
    orientation = relativeOrient * prevOrientation;
    location    = prevLocation + relativeLoc * prevOrientation;
    vSet = updateView(vSet, viewId, 'Orientation', orientation, ...
        'Location', location);
    
    % Find point tracks across all views.
    tracks = findTracks(vSet);

    % Get the table containing camera poses for all views.
    camPoses = poses(vSet);

    % Triangulate initial locations for the 3-D world points.
    xyzPoints = triangulateMultiview(tracks, camPoses, intrinsics);
    
    % Refine the 3-D world points and camera poses.
    [xyzPoints, camPoses, reprojectionErrors] = bundleAdjustment(xyzPoints, ...
        tracks, camPoses, intrinsics, 'FixedViewId', 1, ...
        'PointsUndistorted', true);

    % Store the refined camera poses.
    vSet = updateView(vSet, camPoses);

    prevFeatures = currFeatures;
    prevPoints   = currPoints;  
    prevI = I;
end

%% Display camera poses.
camPoses = poses(vSet);
figure(2); clf;
plotCamera(camPoses, 'Size', 0.2);
hold on

% Exclude noisy 3-D points.
goodIdx = (reprojectionErrors < 5);
xyzPoints_ = xyzPoints(goodIdx, :);

% Display the 3-D points.
pcshow(xyzPoints_, 'VerticalAxis', 'y', 'VerticalAxisDir', 'down', ...
    'MarkerSize', 45);
grid on
hold off

% Specify the viewing volume.
loc1 = camPoses.Location{1};
xlim([loc1(1)-10, loc1(1)+10]);
ylim([loc1(2)-10, loc1(2)+10]);
zlim([loc1(3)-1, loc1(3)+50]);
camorbit(0, -30);

title('Points and Camera Poses');

%% reproject all points into an image
useId = 1; % can be 1 to numImagesToLoad;
newCamParams = cameraParameters( 'IntrinsicMatrix', intrinsics.IntrinsicMatrix );
[rot, trans] = cameraPoseToExtrinsics( camPoses.Orientation{useId}, camPoses.Location{useId} );
% or manually:
% loc = camPoses.Location{useId};
% rot = camPoses.Orientation{useId}';
% trans = -loc*rot;
reprojPoints = worldToImage( newCamParams, rot, trans, xyzPoints );

figure(3);
imshow( images{useId} ); hold on;
plot( reprojPoints(:,1), reprojPoints(:,2), 'k.' );
title('reprojected points');

%% dense reconstruction

% undistort the first image
I = greys{1}; 

% Detect corners in the first image.
prevPoints = detectMinEigenFeatures(I, 'MinQuality', 0.001, 'ROI', roi );
% display
figure(4);
imshow( I ); hold on; title( 'dense features' );
plot( prevPoints.Location(:,1), prevPoints.Location(:,2), 'g.' );


% Create the point tracker object to track the points across views.
tracker = vision.PointTracker('MaxBidirectionalError', 1, 'NumPyramidLevels', 6);

% Initialize the point tracker.
prevPoints = prevPoints.Location;
initialize(tracker, prevPoints, I);

% Store the dense points in the view set.
vSet = updateConnection(vSet, 1, 2, 'Matches', zeros(0, 2));
vSet = updateView(vSet, 1, 'Points', prevPoints);

% Track the points across all views.
for i = 2:numel(images)
    prevI = I;
    % Read undistorted current image.
    I = greys{i}; 
    
    % Track the points.
    [currPoints, validIdx] = step(tracker, I);
    
    % Clear the old matches between the points.
    if i < numel(images)
        vSet = updateConnection(vSet, i, i+1, 'Matches', zeros(0, 2));
    end
    vSet = updateView(vSet, i, 'Points', currPoints);
    
    % Store the point matches in the view set.
    matches = repmat((1:size(prevPoints, 1))', [1, 2]);
    matches = matches(validIdx, :);        
    vSet = updateConnection(vSet, i-1, i, 'Matches', matches);
    
    % show:
    figure(5);
    showMatchedFeatures(prevI, I, prevPoints, currPoints, 'montage');
    title( 'dense matches' );
    drawnow;
end

% Find point tracks across all views.
tracks = findTracks(vSet);

% Find point tracks across all views.
camPoses = poses(vSet);

% Triangulate initial locations for the 3-D world points.
xyzPoints = triangulateMultiview(tracks, camPoses,...
    intrinsics);

% Refine the 3-D world points and camera poses.
[xyzPoints, camPoses, reprojectionErrors] = bundleAdjustment(...
    xyzPoints, tracks, camPoses, intrinsics, 'FixedViewId', 1, ...
    'PointsUndistorted', true);

% Display the dense points and refined camera poses.
figure(6);
plotCamera(camPoses, 'Size', 0.2);
hold on

% Exclude noisy 3-D world points.
goodIdx = (reprojectionErrors < 5);

% Display the dense 3-D world points.
pcshow(xyzPoints(goodIdx, :), 'VerticalAxis', 'y', 'VerticalAxisDir', 'down', ...
    'MarkerSize', 45);
grid on
hold off

% Specify the viewing volume.
loc1 = camPoses.Location{1};
xlim([loc1(1)-10, loc1(1)+10]);
ylim([loc1(2)-10, loc1(2)+10]);
zlim([loc1(3)-1, loc1(3)+50]);
camorbit(0, -30);
% Note: some points outside the viewing volume are clipped!

title('Dense Reconstruction');

%% reproject all (dense) points into an image
useId = 1; % can be 1 to numImagesToLoad;
newCamParams = cameraParameters( 'IntrinsicMatrix', intrinsics.IntrinsicMatrix );
[rot, trans] = cameraPoseToExtrinsics( camPoses.Orientation{useId}, camPoses.Location{useId} );
reprojPoints = worldToImage( newCamParams, rot, trans, xyzPoints );

figure(7);
imshow( images{useId} ); hold on;
plot( reprojPoints(:,1), reprojPoints(:,2), 'k.' );
title('reprojected dense points');



%% reproject an individual point onto all images
pt = [95.3350 -7.3158 188.0465]; % point on the tree in the background

numRows = 2; % number of rows for subplot
figure(8);

for i = 1:numImagesToLoad
   
    % manually convert pose to extrinsic
    loc = camPoses.Location{useId};
    rot = camPoses.Orientation{useId}';
    trans = -loc*rot;
    
    reproj = worldToImage( newCamParams, rot, trans, pt );

    subplot( numRows, ceil(numImagesToLoad/numRows), i );
    imshow( images{i} ); hold on; title( imagelist{i} );
    plot( reproj(:,1), reproj(:,2), 'r+' );
end


