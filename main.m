clear; clc; close all; 
%----------------------
addpath('modelspecific'); 

%% read images
imgpath = 'Imgs\'; img_format = '*.jpg';
outpath = [imgpath, 'results\'];%results
dir_folder = dir(strcat(imgpath, img_format));

path1 =  sprintf('%s%s',imgpath, dir_folder(1).name); %
path2 =  sprintf('%s%s',imgpath, dir_folder(2).name); %
img1 = im2double(imread(path1));  % 
img2 = im2double(imread(path2));  % 

%% detect features and align images
fprintf('> feature matching and image alignment...');tic;
[warped_img1, warped_img2] = registerTexture(img1, img2);
fprintf('done (%fs)\n', toc);    

%% iterative seam estimation
fprintf('> seam estimation and image blending...');tic;
blendTexture(warped_img1, warped_img2);
fprintf('done (%fs)\n', toc);

