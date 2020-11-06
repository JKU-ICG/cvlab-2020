function [FP, TP, GT] = computeFpTpFn( detections, gts, iou_threshold, conf_threshold )
% computes false and true positives, given detections, ground truths an iou and confidence threshold.
%%
% Validate user inputs
info = evaluationInputValidation(detections, ...
    gts, 'evaluateDetectionPrecision', true, iou_threshold);
% Match the detection results with ground truth
s = evaluateDetection(detections, info, iou_threshold);

FP = 0;
TP = 0;
GT = 0;
for i_s = 1:length(s)
   for i_l = 1:length(s(i_s).labels)
       if s(i_s).scores(i_l) >= conf_threshold
           if s(i_s).labels(i_l) == 0
               FP = FP + 1;
           else
               TP = TP + 1;
           end
       end
   end
   GT = GT + size(gts(i_s,:).person{:},1);
end


% --- from internal Matlab functions below ---
end

function info = evaluationInputValidation(detectionResults, groundTruth, mfilename, checkScore, varargin)
% validate inputs for detection evaluation functions

info.EvaluationInputWasTable = istable(groundTruth);

if info.EvaluationInputWasTable
    info.GroundTruthData = groundTruth;
    info.ClassNames = groundTruth.Properties.VariableNames;
else
    try
        [info.GroundTruthData, info.ClassNames] = ...
            vision.internal.detector.checkAndGetEvaluationInputDatastore(groundTruth, mfilename);
    catch
        info.ClassNames = {};
    end
end

if checkScore
    % verify detection result
    checkDetectionResultsTable(detectionResults, info.ClassNames, mfilename);
else
    % verify bounding boxes
    checkBoundingBoxTable(detectionResults, info.ClassNames, mfilename);
end

if info.EvaluationInputWasTable
    % verify ground truth table
    checkGroundTruthTable(groundTruth, height(detectionResults), mfilename);
else
    if ~isfield(info, 'GroundTruthData')
        [info.GroundTruthData, info.ClassNames] = ...
            vision.internal.detector.checkAndGetEvaluationInputDatastore(groundTruth, mfilename);
    end
end

% check additional inputs
if ~isempty(varargin)
    validateattributes(varargin{1}, {'single','double'}, ...
        {'real','scalar','nonsparse','>=',0,'<=',1}, mfilename, 'threshold');
end
end

%==========================================================================
function checkDetectionResultsTable(detectionResults, classNames, mfilename)

    validateattributes(detectionResults, {'table'},{'nonempty'}, mfilename, 'detectionResults');

    if width(detectionResults) < 2
        error(message('vision:ObjectDetector:detectionResultsTableWidthLessThanTwo'));
    end
    
    ismulcls = (width(detectionResults) > 2);
    if ismulcls
        classNames = categorical(classNames);
        msg = '{';
        for n = 1:numel(classNames)
            msg = [msg char(classNames(n)) ','];
        end
        msg = [msg(1:end-1) '}'];
    end

    for i = 1:height(detectionResults)
        % check bounding boxes
        try
            iAssertIsScalarCell(detectionResults{i, 1});
            if ~isempty(detectionResults{i, 1}{1})
               
                bbox = detectionResults{i, 1}{1};
                validateattributes(bbox, ...
                    {'numeric'},{'real','nonsparse','2d', 'size', [NaN, 4]});
                if (any(bbox(:,3)<=0) || any(bbox(:,4)<=0))
                    error(message('vision:visionlib:invalidBboxHeightWidth'));
                end
            end
        catch ME            
            error(message('vision:ObjectDetector:invalidBboxInDetectionTable', i, ME.message(1:end-1)));
        end
        
        % check scores
        try
            if ~isempty(detectionResults{i, 1}{1})
                iAssertIsScalarCell(detectionResults{i, 2});
                validateattributes(detectionResults{i, 2}{1},{'single','double'},...
                    {'vector','real','nonsparse','numel',size(detectionResults{i, 1}{1},1)});
            end
        catch ME
            error(message('vision:ObjectDetector:invalidScoreInDetectionTable', i, ME.message(1:end-1)));
        end
        
        % for multi-class detection, check labels
        if ismulcls
            try
                if ~isempty(detectionResults{i, 1}{1})
                    iAssertIsScalarCell(detectionResults{i, 3});
                    validateattributes(detectionResults{i, 3}{1},{'categorical'},...
                        {'vector','numel',size(detectionResults{i, 1}{1},1)});
                end
            catch ME
                error(message('vision:ObjectDetector:invalidLabelInDetectionTable', i, ME.message(1:end-1)));
            end
            
            if ~isempty(detectionResults{i, 1}{1})
                labels = categories(detectionResults{i, 3}{1});
                if any(isundefined(detectionResults{i, 3}{1}))||~all(ismember(labels, classNames))
                    error(message('vision:ObjectDetector:undefinedLabelInDetectionTable', i, msg));
                end
            end
        end
        
    end  
end

%==========================================================================
function checkGroundTruthTable(groundTruthData, numExpectedRows, mfilename)

    validateattributes(groundTruthData, {'table'}, ...
        {'nonempty','nrows',numExpectedRows}, mfilename, 'groundTruthData');

    for n = 1 : width(groundTruthData)
        for i = 1:numExpectedRows
            try      
                iAssertIsScalarCell(groundTruthData{i, n});
                if ~isempty(groundTruthData{i, n}{1})
                    bbox = groundTruthData{i, n}{1};
                    validateattributes(bbox, ...
                        {'numeric'},{'real','nonsparse','2d', 'size', [NaN, 4]});
                    if (any(bbox(:,3)<=0) || any(bbox(:,4)<=0))
                        error(message('vision:visionlib:invalidBboxHeightWidth'));
                    end
                end
            catch ME
                error(message('vision:ObjectDetector:invalidBboxInTrainingDataTable', i, n, ME.message(1:end-1)));
            end        
        end  
    end
end 

%==========================================================================
function checkBoundingBoxTable(boundingBoxes, classNames, mfilename)

    validateattributes(boundingBoxes, {'table'},{'nonempty'}, mfilename, 'boundingBoxes');
    
    ismulcls = (width(boundingBoxes) >= 2);
    if ismulcls
        classNames = categorical(classNames);
        msg = '{';
        for n = 1:numel(classNames)
            msg = [msg char(classNames(n)) ','];
        end
        msg = [msg(1:end-1) '}'];
    end

    for i = 1:height(boundingBoxes)
        iAssertIsScalarCell(boundingBoxes{i, 1});
        bbox = boundingBoxes{i, 1}{1};
        % check bounding boxes
        try
            if ~isempty(bbox)
                validateattributes(bbox, ...
                    {'numeric'},{'real','nonsparse','2d', 'size', [NaN, 4]});
                if (any(bbox(:,3)<=0) || any(bbox(:,4)<=0))
                    error(message('vision:visionlib:invalidBboxHeightWidth'));
                end                
            end
        catch ME
            error(message('vision:ObjectDetector:invalidBboxInBboxTable', i, ME.message(1:end-1)));
        end
                
        % for multi-class, check labels
        if ismulcls
            try
                if ~isempty(bbox)
                    iAssertIsScalarCell(boundingBoxes{i, 2});
                    validateattributes(boundingBoxes{i, 2}{1},{'categorical'},...
                        {'vector','numel',size(bbox,1)});
                end
            catch ME
                error(message('vision:ObjectDetector:invalidLabelInBboxTable', i, ME.message(1:end-1)));
            end
            
            if ~isempty(bbox)
                labels = categories(boundingBoxes{i, 2}{1});
                if any(isundefined(boundingBoxes{i, 2}{1}))||~all(ismember(labels, classNames))
                    error(message('vision:ObjectDetector:undefinedLabelInBboxTable', i, msg));
                end
            end
        end
        
    end  
end

%--------------------------------------------------------------------------
function iAssertIsScalarCell(x)
validateattributes(x, {'cell'}, {'scalar'});
end


function s = evaluateDetection(detectionResults,info,threshold,checkScore)
% Return per image detection evaluation result.
% detectionResults is a table of one/two/three columns: boxes, scores, labels
% groundTruth is a table of boxes, one column for each class
% threshold is the intersection-over-union (IOU) threshold. 
% checkScore is true if the detectionResults has scores in its second
% column

% Copyright 2016-2017 The MathWorks, Inc.

numImages = height(detectionResults);
numClasses = numel(info.ClassNames);

allResults = iPreallocatePerImageResultsStruct(numImages);

if nargin < 4
    checkScore = true;
end

if checkScore
    ismulcls = (width(detectionResults) > 2);
    labelCol = 3;
else
    ismulcls = (width(detectionResults) > 1);
    labelCol = 2;
end

if ismulcls
    classNames = categorical(info.ClassNames);
end

for i = 1:numImages
        
    [expectedBoxes, expectedLabelIDs] = iGetGroundTruthBoxes(info.GroundTruthData, i, info);
    if isempty(expectedBoxes)
        expectedBoxes = zeros(0, 4, 'like', expectedBoxes);
    end
 
    bboxes = detectionResults{i, 1}{1};
    
    if checkScore
        scores = detectionResults{i, 2}{1};
    else
        scores = [];
    end
    
    if ismulcls
        detLabelIDs = detectionResults{i, labelCol}{1};
        
        if ~isempty(detLabelIDs)
            % convert to numeric values
            [~, detLabelIDs] = ismember(detLabelIDs,classNames);
        else
            detLabelIDs = [];
        end
    else
        detLabelIDs = ones(size(bboxes, 1), 1);
    end
    
    results = iPreallocatePerClassResultsStruct(numClasses);
    
    for c = 1:numClasses
    
        if info.EvaluationInputWasTable
            expectedBoxesForClass = expectedBoxes(expectedLabelIDs == c, :);
        else
            expectedBoxesForClass = expectedBoxes(expectedLabelIDs == info.ClassNames{c}, :);
        end
               
        if isempty(bboxes)
            scoresPerClass = [];
            bboxesPerClass = zeros(0, 4, 'like', bboxes);
        else
            if checkScore
                scoresPerClass = scores(detLabelIDs == c);
            else
                scoresPerClass = [];
            end
            bboxesPerClass = bboxes(detLabelIDs == c, :);
        end
        
        if ~isempty(expectedBoxesForClass)
            [labels, falseNegative, assignments] = ...
                vision.internal.detector.assignDetectionsToGroundTruth(bboxesPerClass, ...
                    expectedBoxesForClass, threshold, scoresPerClass);
        else
            labels = zeros(size(bboxesPerClass, 1),1);
            falseNegative = 0;
            assignments = [];
        end
        % per class per image results       
        results(c).labels = labels;
        results(c).scores = scoresPerClass;
        results(c).Detections = bboxesPerClass;
        results(c).FalseNegative = falseNegative;
        results(c).GroundTruthAssignments = assignments;
        results(c).NumExpected = size(expectedBoxesForClass,1);                  
        
    end
     
    allResults(i).Results = results;
end
   
% vertcat results over all images for each class. Results holds a
% 1xnumClasses struct array. After concat s is numImages-by-numClasses
% struct array.
s = vertcat(allResults(:).Results);
end

%==========================================================================
function s = iPreallocatePerImageResultsStruct(numImages)
s(numImages) = struct('Results', []);
end

%==========================================================================
function s = iPreallocatePerClassResultsStruct(numClasses)
s(numClasses) = struct(...
    'labels', [], ...
    'scores', [], ...
    'Detections', [], ...
    'FalseNegative', [], ...
    'GroundTruthAssignments', [], ...
    'NumExpected', []);
end

%==========================================================================
function [bboxes, labels] = iGetGroundTruthBoxes(tbl, i, info)
if ~info.EvaluationInputWasTable
    bboxes = tbl{i,1};
    labels = tbl{i,2};
    return;
end
b = tbl(i,:);

n = cellfun(@(x)size(x,1), b{1,:});

label = cell(width(b),1);
for i = 1:width(b)
    label{i} = repelem(i,n(i),1);    
end
labels = vertcat(label{:});
bboxes = vertcat(b{1,:}{:});
end



