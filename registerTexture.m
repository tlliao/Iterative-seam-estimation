function [warped_img1, warped_img2] = registerTexture(img1, img2)
% given two images, detect sift feature matches and calculate the homography warp
% img1: target image to be warped
% img2: reference image
% warped_img1: warped img1
% warped_img2: warped img2

[pts1, pts2] = siftMatch(img1, img2); % sift feature matches
Sz1 = max(size(img1,1),size(img2,1)); % to avoid the two images have different size
Sz2 = max(size(img1,2),size(img2,2));
[matches_1, matches_2] = matchDelete(pts1, pts2, Sz1, Sz2); % delete wrong match features (outliers)

init_H = calcHomo(matches_1, matches_2);  % fundamental homography

[warped_img1, warped_img2] = homographyAlign(img1,img2,init_H); % warped images via homography warp

end