function [BBs, yoloBBs, usedBBs] = saveLabels( projs, imgsize, labelfile )
    % saveLabels computes absolute and relative axis-aligned boundig boxes
    % of the points in projs. If labelfile is specified creates a text file
    % that is compatible with darknet/YOLO.

    OBJCLASS = '0';
    NEWLINE = char(10);
    TAB = char(9);
    
    BBs = zeros( length(projs), 4 );
    yoloBBs = NaN( length(projs), 4 );
    usedBBs = false( length(projs), 1 );
    
    % Due to Matlab notation we need to flip the imagesize
    % dimension 2 is the width and dimension one the height!
    imgsize([2 1]) = imgsize([1 2]); 

% yolo syntax:
%   <object-class> <x> <y> <width> <height>
%   one line for every roi 

    str = '';

    for i = 1:length(projs)
        [minmax,bbsize] = getBoundingBox(projs{i});
        bbiarea = prod(bbsize); % initial area
        
        centers = mean( minmax, 1 );
        assert( length(centers) == size(projs{i},2) ); % 2D
                
        
        % clip bounding boxes that exceed the image border:
        minmax(:,1) = max( 1, min( imgsize(1), minmax(:,1) ) );
        minmax(:,2) = max( 1, min( imgsize(2), minmax(:,2) ) );
        
        bbsize = minmax(2,:) - minmax(1,:);
        if any( bbsize == 0 )
            continue; % boounding box has zero size and got clipped!
        end

        
        BBs(i,:) = minmax(:);
        yoloBB = bbtoYolo(imgsize, minmax(:));
        yoloBBs(i,:) = yoloBB;
        
        % if bounding box is clipped by more than XX% don't use it
        bbarea = prod(bbsize); % new bb area

        if  ( bbarea / bbiarea ) < .25
           continue; 
        end

        % Boundary checks!
%         % if bounding box center is outside of image do not use the label!
%         if ~(     centers(1) > 0 && centers(2) > 0 ...
%            &&   centers(1) <= imgsize(1) && centers(2) <= imgsize(2))
%             continue;
%         end
        
        % STORE:
        usedBBs(i) = true;
        str = [ str, OBJCLASS, ' ', sprintf( '%f ', yoloBB ), NEWLINE ];
    end

    raw = char(str);

    if ~isempty(labelfile)
        fid = fopen(labelfile, 'w'); 
        fwrite(fid,raw); 
        fclose(fid); 
    end

end
