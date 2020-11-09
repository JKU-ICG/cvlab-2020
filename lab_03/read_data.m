% --------------- Example How to Load and Work with our thermal data ------
addpath 'util';
clear all; clc; close all; % clean up!


%% SETUP
linenumber = 4;
site = 'F6';
datapath = fullfile( './data/', site ); 

thermalParams = load( './data/camParams_thermal.mat' ); %load intrinsics
thermalpath = fullfile( datapath, 'Images', num2str(linenumber) ); % path to thermal images
thermalds = datastore( thermalpath );

%% load an image and undistort it
thermal = readimage( thermalds, 16 );  
figure( 'Color', 'white' ); clf;
subplot(2,1,1); imshow( thermal, [] );
title( 'original' );

thermal = undistortImage( thermal, thermalParams.cameraParams );
ax2 = subplot(2,1,2); imshow( thermal, [] );
colormap( ax2, 'parula' );
title( 'undistorted + colormap' );


%% display multiple images of a line
imgIds = [14:18];
figure( 'Color', 'white' ); clf;
for i = 1:length(imgIds)
    thermal = undistortImage( readimage( thermalds, imgIds(i) ), thermalParams.cameraParams );
    subplot(1,length(imgIds),i); imshow( thermal, [] );
end
colormap( 'parula' );

%% compute integral

integral = zeros(size(thermal),'double');

imgIds = [14:18];
for i = 1:length(imgIds)
    thermal = undistortImage( readimage( thermalds, imgIds(i) ), thermalParams.cameraParams );
    integral = integral + double(thermal);
end

figure( 'Color', 'white' ); clf;
imshow( integral, [] );


%% load poses
json = readJSON( fullfile( datapath, '/Poses/', [num2str(linenumber) '.json'] ) );
images = json.images; clear json;

K = thermalParams.cameraParams.IntrinsicMatrix; % intrinsic matrix, is the same for all images
Ms = {};

figure('Color','white','Name','Poses'); hold on;
for i_label = 1:length(imgIds)
   M = images(imgIds(i_label)).M3x4; % read the pose matrix
   M(4,:) = [0,0,0,1];
   Ms{i_label} = M;
   invM = inv(M);
   pos = invM(:,4);
   %M(4,:) = [0,0,0,1]
   cam = plotCamera( 'Location', pos(1:3), 'Size', .2 ); hold on;

end
axis equal
axis off

%% compute integral with warping

integral = zeros(size(thermal),'double');
count = zeros(size(integral),'double');

% warp to a reference image (center view)
M1 = Ms{3};
R1 = M1(1:3,1:3)';
t1 = M1(1:3,4)';

for i = 1:length(imgIds)
    img2 = undistortImage( imread(fullfile(thermalpath,images(imgIds(i)).imagefile)), ...
           thermalParams.cameraParams );
          
    M2 = Ms{i};
    R2 = M2(1:3,1:3)';
    t2 = M2(1:3,4)';

    % relative 
    R = R1' * R2;
    t = t2 - t1 * R;

    z = 10; %getAGL(site); % meter
    P = (inv(K) * R * K ); 
    P_transl =  (t * K);
    P(3,:) = P(3,:) + P_transl./z; % add translation
    tform = projective2d( P );

    % --- warp images ---
    warped2 = double(imwarp(img2,tform.invert(), 'OutputView',imref2d(size(integral))));
    warped2(warped2==0) = NaN; % border introduced by imwarp are replaced by nan
    
    figure(8);
    subplot(1,length(imgIds),i); imshow( warped2, [] );

    count(~isnan(warped2)) = count(~isnan(warped2)) + 1;
    integral(~isnan(warped2)) = integral(~isnan(warped2)) + warped2(~isnan(warped2));
end
colormap( 'parula' );

% normalize
integral = integral ./ count;

h_fig = figure(9);
set( h_fig, 'Color', 'white' ); clf;
imshow( integral, [] ); title( 'integral' );


%% load and display labels

json = readJSON( fullfile( datapath, '/Labels/', ['Label' num2str(linenumber) '.json'] ) );
labels = json.Labels; clear json;

h_fig = figure(10);
set( h_fig, 'Color', 'white' ); clf;
imshow( integral, [] ); title( 'integral with labels' );

% draw polygonal labels
for i_label = 1:length(labels)
    poly = labels(i_label).poly;
    assert( strcmpi( images(imgIds(3)).imagefile, labels(i_label).imagefile ), 'something went wrong: imagefile names of label and poses do not match!' );
    drawpolygon( 'Position', poly );
end

%% axis-aligned bounding box labels
h_fig = figure(11);
set( h_fig, 'Color', 'white' ); clf;
imshow( integral, [] ); title( 'integral with AABB labels' );
% draw AABBs 
if ~isempty(labels) && ~isempty({labels.poly})
    [absBBs, relBBs, ~] = saveLabels( {labels.poly}, size(integral), [] );


    for i_proj = 1:size(absBBs,1)
        x1 = absBBs(i_proj,1); x2 = absBBs(i_proj,2); 
        y1 = absBBs(i_proj,3); y2 = absBBs(i_proj,4);
        aabb = [[x2 y1];[x1 y1];[x1 y2];[x2 y2]];
        h = drawpolygon('Position',aabb, 'Color', 'yellow');
    end
end


