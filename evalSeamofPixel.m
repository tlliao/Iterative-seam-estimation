function [ eval_signal ] = evalSeamofPixel(imgdif, B_rgb, BoundPts)
    % point evaluation for stitching seam
    % for pixels along the seam, calculate the differences between pixels with different labels
Bound_Num = size(BoundPts,1);
eval_signal = zeros(Bound_Num,1);

for i=1:Bound_Num
    i_bound = BoundPts(i,1);
    j_bound = BoundPts(i,2);

    if i_bound>1 && ~B_rgb(i_bound-1, j_bound)
        edgecost = (imgdif(i_bound-1,j_bound)+imgdif(i_bound,j_bound))/2;
    end
    if i_bound<size(B_rgb,1) && ~B_rgb(i_bound+1,j_bound)
        edgecost = (imgdif(i_bound+1,j_bound)+imgdif(i_bound,j_bound))/2;
    end
    if j_bound>1 && ~B_rgb(i_bound,j_bound-1)
        edgecost = (imgdif(i_bound,j_bound-1)+imgdif(i_bound,j_bound))/2;
    end
    if j_bound<size(B_rgb,2) && ~B_rgb(i_bound,j_bound+1)
        edgecost = (imgdif(i_bound,j_bound+1)+imgdif(i_bound,j_bound))/2;
    end        
    eval_signal(i) = edgecost;

end

end

