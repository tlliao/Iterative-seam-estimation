function [ hybrid_signal, boundarypts ] = seamRefining( gray1, gray2, imgdif, C, B_contour, patchsize)
% given seam information, calculate the patch/pixel signals and denoised
% hybrid signal, return the output signal and extend seam points
B_seam = B_contour;
if sum(B_seam(1:end, 1))==size(B_seam,1)
    B_seam = ~B_seam;   %% to find out the reference is on the left or right
    B_seam = imdilate(imerode(B_seam, strel('square', 2)), strel('square', 2));
else
    B_seam = imdilate(imerode(B_seam, strel('square', 2)), strel('square', 2));
end

if sum(B_seam(1:end,1)) + sum(B_seam(1,1:end))==0
    rotate_B_seam = B_seam(1+size(B_seam,1)-1:-1:1+size(B_seam,1)-end, 1+size(B_seam,2)-1:-1:1+size(B_seam,2)-end);
    boundarypts = contourTracingofRight(~rotate_B_seam);
    boundarypts = [1+size(B_seam,1)-boundarypts(:,1), 1+size(B_seam,2)-boundarypts(:,2)];
else
    boundarypts = contourTracingofRight(B_seam);
end
    
patch_signal = evalSeamofSSIM(gray1, gray2, C, boundarypts, patchsize); % patch signal
pixel_signal = evalSeamofPixel(imgdif, B_seam, boundarypts); % pixel signal

denoise_patch_signal = signalDenoise(patch_signal);  % denoise patch signal
denoise_pixel_signal = signalDenoise(pixel_signal);  % denoise pixel signal
hybrid_signal = 10.*denoise_patch_signal.*denoise_pixel_signal;  % hybrid signal

end

