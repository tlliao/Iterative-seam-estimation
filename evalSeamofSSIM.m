function [ eval_signal ] = evalSeamofSSIM(gray1, gray2, C_lap, Boundpts, patchsize)
% evaluate the seam according to patch difference between input images (img1,img2)
Bound_Num = size(Boundpts,1);
eval_signal = zeros(Bound_Num,1);

for i=1:Bound_Num
    i_bound = Boundpts(i,1);
    j_bound = Boundpts(i,2);

    x1 = max(i_bound-(patchsize-1)/2, 1);
    x2 = min(i_bound+(patchsize-1)/2, size(gray1,1));
    y1 = max(j_bound-(patchsize-1)/2, 1);
    y2 = min(j_bound+(patchsize-1)/2, size(gray1,2));
    patch_mask = C_lap(x1:x2,y1:y2);
    tensity1 = gray1(x1:x2,y1:y2);
    tensity2 = gray2(x1:x2,y1:y2);
    tensity1 = tensity1(patch_mask);
    tensity2 = tensity2(patch_mask);

    tensity_ssim = ssim(tensity1, tensity2);

    eval_signal(i) = max(0, (1-tensity_ssim)/2); 
end

end