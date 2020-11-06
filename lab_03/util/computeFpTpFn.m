function [FP, TP, GT] = computeFpTpFn( detections, gts, iou_threshold, conf_threshold )
% computes false and true positives, given detections, ground truths an iou and confidence threshold.
%%
% Validate user inputs
info = vision.internal.detector.evaluationInputValidation(detections, ...
    gts, 'evaluateDetectionPrecision', true, iou_threshold);
% Match the detection results with ground truth
s = vision.internal.detector.evaluateDetection(detections, info, iou_threshold);

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

