function box = yoloToBB(imgsize, yoloBB)
% convert relative BB (as used in YOLO) coordinates to absolute coordinates, 
% from the voc_label python script of yolo/darknet
    dw = 1./(imgsize(1));
    dh = 1./(imgsize(2));
    box = zeros(4,1);
    
    %     x = (box(1) + box(2))/2.0 - 1;
    %     y = (box(3) + box(4))/2.0 - 1;
    %     w = box(2) - box(1);
    %     h = box(4) - box(3);
    %     x = x*dw;
    %     w = w*dw;
    %     y = y*dh;
    %     h = h*dh;
    %     yoloBB = [x,y,w,h];
    % reverse of the above (bbToYolo.m)
    if isnumeric(yoloBB)
        x = yoloBB(1); y = yoloBB(2); w = yoloBB(3); h = yoloBB(4);
    elseif isstruct(yoloBB)
       x = yoloBB.center_x; y = yoloBB.center_y;
       w = yoloBB.width; h = yoloBB.height;
    else
        error( 'yoloBB has a format that is not supported!' );
    end
    w = w/dw; x = x/dw;
    h = h/dh; y = y/dh;
    box(1) = x + 1 - w/2; % left
    box(2) = box(1) + w - 1; % right
    box(3) = (y+1) - h/2; % top
    box(4) = box(3) + h - 1; % bottom
end