function [filenames, matDetections, matGT, matIoUs, matIoUGTids] = parseResults( results, imgsize )
% parses results structure so that we can computer AP, FP, and TP scores.

if nargin < 2
    imgsize = [512, 640];
end

%%

labeledImages = {}; filenames = {};

matGTBBs = cell(length( results ),1);
matDectBBs = cell(length( results ),1);
matDectConfs = cell(length( results ),1);
matIoUs = cell(length( results ),1);
matIoUGTids = cell(length( results ),1);


for i = 1:length( results )
    [ folder, name, ext] = fileparts( results(i).filename );
    site = name(1:strfind(name, '_line')-1);
    linenumber = str2double( name(strfind(name, '_line')+strlength('_line'):end) );
        
    json = readJSON( fullfile( 'data', site, '/Labels/', ['Label' num2str(linenumber) '.json'] ) );
    labels = json.Labels; clear json;
    if ~isempty(labels) && ~isempty({labels.poly})
        [~, yoloBBs, ~] = saveLabels( {labels.poly}, imgsize, [] );
        lblBBs = zeros( size(yoloBBs,1), 4 );
        for ii = 1:size(yoloBBs,1)
            bb = yoloToBB( imgsize, yoloBBs(ii,:) );
            lblBBs(ii,:) = [bb(1),bb(3),bb(2)-bb(1),bb(4)-bb(3)];
        end
    else
        lblBBs = zeros( 0, 4 );
    end
    matGTBBs{i} = lblBBs;
   
        
    if ~isempty( results(i).objects )
        % draw detected objects
        mBBs = zeros( length(results(i).objects), 4 );
        mBBCenters = zeros( length(results(i).objects), 2 );
        mConfs = zeros(  length(results(i).objects), 1 );
        mIoUs = zeros(  length(results(i).objects), 1 );
        mIoUgtIds = zeros(  length(results(i).objects), 1 );
        

        for ii = 1:length( results(i).objects )
            bb = yoloToBB( imgsize, results(i).objects(ii).relative_coordinates );
            
            mBBs(ii,:) = [bb(1),bb(3),bb(2)-bb(1),bb(4)-bb(3)];
            mConfs(ii) = results(i).objects(ii).confidence;
            mBBCenters(ii,:) = [(bb(1)+bb(2))/2,(bb(3)+bb(4))/2]; % BB centers
        end
        
        
        if ~isempty( matGTBBs{i} )
            % computer intersect over union to GT BBs
            allOverlaps = bboxOverlapRatio(matGTBBs{i},mBBs(:,:));
            
            % get maximum for every detection!
            [mIoUs, mIoUgtIds] = max( allOverlaps(:,:), [], 1 );
        end

      
        % store BBs
        matDectBBs{i} = mBBs;
        matDectConfs{i} = mConfs;
        matIoUs{i} =  zeros(  length(results(i).objects), 1 );
        matIoUGTids{i} =  zeros(  length(results(i).objects), 1 );
        matIoUs{i}(:,1) = mIoUs;
        matIoUGTids{i}(:,1) = mIoUgtIds;
    end
    
   
    filenames{i} = [name,ext];
end % for i

matGT = table( matGTBBs, 'VariableNames', {'person'} );
matDetections = table( matDectBBs, matDectConfs, 'VariableNames', {'bboxes', 'scores'} );
