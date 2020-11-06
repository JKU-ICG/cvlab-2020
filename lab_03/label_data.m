% --------------- Example How to Load and Work with our thermal data ------
addpath 'util'
clear all; clc; close all; % clean up!

%%
trainingsites = { 'F0', 'F1', 'F2', 'F3', 'F5', 'F6', 'F8', 'F9', 'F10', 'F11' }; % Note, we use the same IDs as in the Nature Machine Intelligence Paper.
testsites = { 'T1', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'T8'};
allsites = cat(2, trainingsites, testsites );



for i_site = 1:length(allsites)
%%
%linenumber = '4';
site = allsites{i_site}
datapath = fullfile( './data/', site ); 

thermalParams = load( './data/camParams_thermal.mat' );
%%

for linenumber = 1:99
    if ~isfile(fullfile( datapath, '/Poses/', [num2str(linenumber) '.json'] ))
        continue % SKIP!
    end

    json = readJSON( fullfile( datapath, '/Poses/', [num2str(linenumber) '.json'] ) );
    images = json.images; clear json;

    try
        json = readJSON( fullfile( datapath, '/Labels/', ['Label' num2str(linenumber) '.json'] ) );
        labels = json.Labels; clear json;
    catch
       warning( 'no Labels defined!!!' ); 
       labels = []; % empty
    end

    K = thermalParams.cameraParams.IntrinsicMatrix; % intrinsic matrix, is the same for all images
    Ms = {};

    thermalpath = fullfile( datapath, 'Images', num2str(linenumber) );

    figure(100); hold on;
    for i_label = 1:length(images)
       thermal = undistortImage( imread(fullfile(thermalpath,images(i_label).imagefile)), ...
           thermalParams.cameraParams );
       M = images(i_label).M3x4;
       M(4,:) = [0,0,0,1];
       Ms{i_label} = M;
       invM = inv(M);
       pos = invM(:,4);
       %M(4,:) = [0,0,0,1]
       cam = plotCamera( 'Location', pos(1:3), 'Size', .2 ); hold on;

    end
    axis equal




    %%
    refId = (round(length(images)/2))+1; % compute center by taking the average id!
    imgr = undistortImage( imread(fullfile(thermalpath,images(refId).imagefile)), ...
           thermalParams.cameraParams );
    M1 = Ms{refId};
    R1 = M1(1:3,1:3)';
    t1 = M1(1:3,4)';
    range = [min(imgr(:)), max(imgr(:))];
    integral = zeros(size(imgr),'double');
    count = zeros(size(imgr),'double');

    for i_label = 1:length(images)
        img2 = undistortImage( imread(fullfile(thermalpath,images(i_label).imagefile)), ...
               thermalParams.cameraParams );


        M2 = Ms{i_label};
        R2 = M2(1:3,1:3)';
        t2 = M2(1:3,4)';

        % relative 
        R = R1' * R2;
        t = t2 - t1 * R;

        z = getAGL( site ); % meters
        % the checkerboard is ~900 millimeters away
        % the tree in the background is ~100000 millimeters (100 m)
        P = (inv(K) * R * K ); 
        P_transl =  (t * K);
        P_ = P; % copy
        P_(3,:) = P_(3,:) + P_transl./z; % add translation
        tform = projective2d( P_ );

        % --- warp images ---
        % rgb on thermal
        warped2 = double(imwarp(img2,tform.invert(), 'OutputView',imref2d(size(imgr))));
        warped2(warped2==0) = NaN; % border introduced by imwarp are replaced by nan
        % DEBUG: figure(99); imshow(warped2,range); drawnow;

        count(~isnan(warped2)) = count(~isnan(warped2)) + 1;
        integral(~isnan(warped2)) = integral(~isnan(warped2)) + warped2(~isnan(warped2));

    end


    h_fig = figure(100+linenumber); clf; % continue figure ...
    set( h_fig, 'name', sprintf( '%s line %d', site, linenumber ) );
    imshow( integral ./ count, [] );


    % project labels
    figure(h_fig);
    K_ = K; K_(4,4) = 1.0;

    for i_label = 1:length(labels)
       if isempty(labels) || isempty(labels(i_label).poly)
           continue;
       end
        
       if ~isfield( labels, 'imagefile' ) 
           wPts = labels(i_label).polyDEM; 
           wPts(:,4) = 1;
           camPts = wPts(:,:) * M1';
           poly = camPts * K_;
           poly = poly(:,1:2) ./ poly(:,3);
           labels(i_label).poly = poly;
       else
          poly = labels(i_label).poly;
          assert( strcmpi( images(refId).imagefile, labels(i_label).imagefile ) );
          if isfield( labels, 'polyDEM' )
            labels = rmfield( labels, 'polyDEM' );
          end
       end
       
    end
    
    %% labeling
    delete 'updated_labels.mat';
    if isempty(labels) || isempty(labels(i_label).poly)
        h_labeler = line_labeler( integral ./ count, {{ }}, 'updated_labels.mat' );
    else
        h_labeler = line_labeler( integral ./ count, {{ labels.poly }}, 'updated_labels.mat' );
    end
    while isvalid(h_labeler)
       pause(.1); % BLOCKING 
    end
    
    if isfile( 'updated_labels.mat' )
       nlabels = load('updated_labels.mat'); 
       for i_label = 1:length(nlabels.line_rois{1})
            labels(i_label).poly = nlabels.line_rois{1}{i_label};
            labels(i_label).imagefile = images(refId).imagefile;
            labels(i_label).class = 0;
       end
       
       writeJSON( struct( 'Labels', labels ), fullfile( datapath, '/Labels/', ['Label' num2str(linenumber) '.json'] ) );
    end

    %h = drawpolygon('Position',poly);
    

end



end


return;

%%
id1 = 10; id2 = 14;

img1 = undistortImage( imread(fullfile(thermalpath,images(id1).imagefile)), ...
       thermalParams.cameraParams );
img2 = undistortImage( imread(fullfile(thermalpath,images(id2).imagefile)), ...
       thermalParams.cameraParams );

M1 = Ms{id1};
R1 = M1(1:3,1:3);
t1 = M1(1:3,4)';
M2 = Ms{id2};
R2 = M2(1:3,1:3);
t2 = M2(1:3,4)';
figure(100); clf; % continue figure ...
subplot(1,3,1); 
imshowpair( img1, img2, 'falsecolor' );

% relative 
R = R1' * R2;
t = t2 - t1 * R;

z = 35; % meters
% the checkerboard is ~900 millimeters away
% the tree in the background is ~100000 millimeters (100 m)
P = (inv(K) * R * K ); 
P_transl =  (t * K);
P_ = P; % copy
P_(3,:) = P_(3,:) + P_transl./z; % add translation
tform = projective2d( P_ );

% --- warp images ---
% rgb on thermal
warped2 = imwarp(img2,tform.invert(), 'OutputView',imref2d(size(img1)));

figure(100); % continue figure ...
%subplot(2,2,3); imshow( warpedthermal ); title( 'warped thermal' ); hold on;
%plot( rgb_imagePoints(:,1), rgb_imagePoints(:,2), 'rx' );
%subplot(1,3,2); imshow( warped2, [min(img2(:)) max(img2(:))] );  title ( 'warped RGB' ); hold on;
%plot( thermal_imagePoints(:,1), thermal_imagePoints(:,2), 'rx' );
%imshowpair( img1, warped2, 'falsecolor' );

subplot(1,3,2); imshow( warped1, [min(img2(:)) max(img2(:))] );

warped1 = imwarp(img1,tform, 'OutputView',imref2d(size(img2)));
subplot(1,3,3); %imshow( warped1, [min(img2(:)) max(img2(:))] );  title ( 'warped RGB' ); hold on;
imshowpair( img2, warped1, 'falsecolor' );

