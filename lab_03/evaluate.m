% --------------- Example How to Load and Work with our thermal data ------
% This scripts computes the average precision and FP and TP for our
% testscenes!
addpath 'util'
clear all; clc; close all; % clean up!
iou_threshold = .10;
conf_threshold = .09;

%%
trainingsites = { 'F0', 'F1', 'F2', 'F3', 'F5', 'F6', 'F8', 'F9', 'F10', 'F11' }; % Note, we use the same IDs as in the Nature Machine Intelligence Paper.
testsites = { 'T1', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'T8'};
allsites = cat(2, trainingsites, testsites );

% baseline results
results = readJSON( './results/yolov4-tiny_integral_results.json' );
[ filenames, detections, gts, ious, gtids] = parseResults( results );

averagePrecision = evaluateDetectionPrecision(detections,gts,iou_threshold)

[FP, TP, GT] = computeFpTpFn( detections, gts, iou_threshold, conf_threshold )