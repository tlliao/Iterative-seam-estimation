clear; clc; close all; 
%% Setup VLFeat toolbox.
%----------------------
addpath('modelspecific'); 
cd vlfeat-0.9.20/toolbox;
feval('vl_setup');
cd ../..;

%% read images
imgpath = 'Imgs\'; img_format = '*.jpg';
outpath = [imgpath, 'results\'];%results
dir_folder = dir(strcat(imgpath, img_format));

path1 =  sprintf('%s%s',imgpath, dir_folder(1).name); %
path2 =  sprintf('%s%s',imgpath, dir_folder(2).name); %
img1 = im2double(imread(path1));  % ´ýÆ´½ÓÍ¼
img2 = im2double(imread(path2));  % »ù×¼Í¼

%% detect features and align images
fprintf('> feature matching and image alignment...');tic;
[warped_img1, warped_img2] = registerTexture(img1, img2);
fprintf('done (%fs)\n', toc);    

%% iterative seam estimation
fprintf('> seam estimation and image blending...');tic;
blendTexture(warped_img1, warped_img2);
fprintf('done (%fs)\n', toc);

