function yoloBB = bbtoYolo(imgsize, box)
% convert absolute BB coordinates to relative coordinates, as used in YOLO
% from the voc_label python script of yolo/darknet (scripts/voc_label.py)
    dw = 1./(imgsize(1));
    dh = 1./(imgsize(2));
    x = (box(1) + box(2) - 1)/2.0; % removed outter -1 and added -1, because of matlab indexing
    y = (box(3) + box(4) - 1)/2.0;
    w = box(2) - box(1) + 1; % added +1, because of matlab indexing
    h = box(4) - box(3) + 1;
    x = x*dw;
    w = w*dw;
    y = y*dh;
    h = h*dh;
    yoloBB = [x,y,w,h];
    
end

