% --------------- Example How to Load and Work with our thermal data ------
% this script computes integrals for every line and writes it into results.
% Additionally labels as AABBs are stored in text files. 
addpath 'util'
clear all; clc; close all; % clean up!

%%
trainingsites = { 'F0', 'F1', 'F2', 'F3', 'F5', 'F6', 'F8', 'F9', 'F10', 'F11' }; % Note, we use the same IDs as in the Nature Machine Intelligence Paper.
testsites = { 'T1', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'T8'};
allsites = cat(2, trainingsites, testsites );



for i_site = 1:length(allsites)

site = allsites{i_site};
datapath = fullfile( './data/', site ); 
if ~isfolder(fullfile( datapath ))
   error( 'folder %s does not exist. Did you download additional data?', datapath );
end

resultsfolder = fullfile( './results/', site );
mkdir(resultsfolder);

thermalParams = load( './data/camParams_thermal.mat' );
%%

% Note: line numbers might not be consecutive and they don't start at index
% 1. So we loop over the posibilities:
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

    for i_label = 1:length(images)
       thermal = undistortImage( imread(fullfile(thermalpath,images(i_label).imagefile)), ...
           thermalParams.cameraParams );
       M = images(i_label).M3x4;
       M(4,:) = [0,0,0,1];
       Ms{i_label} = M;

    end




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
        % warp onto reference image
        warped2 = double(imwarp(img2,tform.invert(), 'OutputView',imref2d(size(imgr))));
        warped2(warped2==0) = NaN; % border introduced by imwarp are replaced by nan

        count(~isnan(warped2)) = count(~isnan(warped2)) + 1;
        integral(~isnan(warped2)) = integral(~isnan(warped2)) + warped2(~isnan(warped2));

    end
    lfr = integral ./ count;

    h_fig = figure(100+linenumber); clf; % continue figure ...
    set( h_fig, 'name', sprintf( '%s line %d', site, linenumber ) );
    imshow( lfr, [] );


    % project labels
    figure(h_fig);
    K_ = K; K_(4,4) = 1.0; % make sure intrinsic is 4x4

    % draw polygon
    for i_label = 1:length(labels)
       if isempty(labels) || isempty(labels(i_label).poly)
           continue;
       end
        
       poly = labels(i_label).poly;
       assert( strcmpi( images(refId).imagefile, labels(i_label).imagefile ), 'something went wrong: imagefile names of label and poses do not match!' );
       drawpolygon( 'Position', poly );
    end
    
    % STORE
    % normalize to [0 1]
    img = lfr - min(lfr(:));
    img = img ./ max(img(:));
    imwrite( img, fullfile( resultsfolder, sprintf( '%s_line%d.png', site, linenumber ) ) );
    
    % draw AABBs and store AABBs
    if ~isempty(labels) && ~isempty({labels.poly})
        [BBs, yoloBBs, usedBBs] = saveLabels( {labels.poly}, size(img), fullfile( resultsfolder, sprintf( '%s_line%d.txt', site, linenumber) ) );
    
    
        for i_proj = 1:size(BBs,1)
            x1 = BBs(i_proj,1); x2 = BBs(i_proj,2); 
            y1 = BBs(i_proj,3); y2 = BBs(i_proj,4);
            aabb = [[x2 y1];[x1 y1];[x1 y2];[x2 y2]];
            h = drawpolygon('Position',aabb);
        end
    else
        % an empty label
        [BBs, yoloBBs, usedBBs] = saveLabels( {}, size(img), fullfile( resultsfolder, sprintf( '%s_line%d.txt', site, linenumber) ) );
    end
    
    

end



end


