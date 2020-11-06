function [AABxyz,range] = getBoundingBox(pts)
% getBoundingBox returns the axis-aligned bounding box of pts in any
% dimension
    dims = size(pts,2);
    AABxyz = zeros(2,dims);
    
    for i = 1:dims
        AABxyz(1,i) = min(pts(:,i));
        AABxyz(2,i) = max(pts(:,i));
    end

    range = AABxyz(2,:) - AABxyz(1,:);

end
