function [ imgout ] = blendTexture(warped_img1, warped_img2)
    %% preparation: parameter initialization
    patchsize = 21; % the size of patch for seam evaluation
    max_iterations = 1000; % maximum iterations for seam estimation
    gray1 = rgb2gray(warped_img1);  gray2 = rgb2gray(warped_img2);  
    square_SE = strel('square', 2);
    signal_mu = 0.12;   %parameters for f(x)=exp(sigma_ratio*(x-mu))
    sigma_ratio = 5;
    
    %%  pre-process of seam-cutting
    w1 = imfill(imbinarize(gray1, 0),'holes');
    w2 = imfill(imbinarize(gray2, 0),'holes');
    A = w1;  B = w2;
    C = A & B;  % overlapping region
    [sz1, sz2] = size(C);
    ind = find(C);  
    nNodes = size(ind,1);
    revindC = zeros(sz1*sz2,1);
    revindC(C)=1:length(ind);
    
    [tmp_y, tmp_x] = find(B==1);
    B_x0 = tmp_x(1); B_y0 = tmp_y(1);  % begining coordinates of reference in final canvas
    B_x1 = tmp_x(end); B_y1 = tmp_y(end); % ending coordinates of reference in final canvas
    
    gray_cut1 = gray1(B_y0:B_y1,B_x0:B_x1);
    gray_cut2 = gray2(B_y0:B_y1,B_x0:B_x1);
    C_cut = C(B_y0:B_y1,B_x0:B_x1);
    
    %%  calculate the data term of the energy function in graph cuts
    % boundary of overlapping region
    BR=(B-[B(:,2:end) false(sz1,1)])>0;
    BL=(B-[false(sz1,1) B(:,1:end-1)])>0;
    BD=(B-[B(2:end,:);false(1,sz2)])>0;
    BU=(B-[false(1,sz2);B(1:end-1,:)])>0;

    CR=(C-[C(:,2:end) false(sz1,1)])>0;
    CL=(C-[false(sz1,1) C(:,1:end-1)])>0;
    CD=(C-[C(2:end,:);false(1,sz2)])>0;
    CU=(C-[false(1,sz2);C(1:end-1,:)])>0;

    imgseedR = (BR|BL|BD|BU)&(CR|CL|CD|CU);
    imgseedB = (CR|CL|CD|CU) & ~imgseedR; 
    
    % data term
    tw=zeros(nNodes,2);
    tw(revindC(imgseedB),2) = inf;
    tw(revindC(imgseedR),1) = inf;
    
    terminalWeights = tw;       % data term

    %% calculate the smoothness term of the energy function
    CL1=C&[C(:,2:end) false(sz1,1)];
    CL2=[false(sz1,1) CL1(:,1:end-1)];
    CU1=C&[C(2:end,:);false(1,sz2)];
    CU2=[false(1,sz2);CU1(1:end-1,:)];
   
    %  edgeWeights:  Euclidean norm
    %--- Smoothness term 
    ang_1 = warped_img1(:,:,1); sat_1 = warped_img1(:,:,2); val_1 = warped_img1(:,:,3);
    ang_2 = warped_img2(:,:,1); sat_2 = warped_img2(:,:,2); val_2 = warped_img2(:,:,3);
    % basic difference map
    imgdif = sqrt( ( (ang_1.*C-ang_2.*C).^2+(sat_1.*C-sat_2.*C).^2+ (val_1.*C-val_2.*C).^2 )./3);
    imgdif_cut = imgdif(B_y0:B_y1,B_x0:B_x1);   
        
    DL = (imgdif(CL1)+imgdif(CL2))./2;
    DU = (imgdif(CU1)+imgdif(CU2))./2;
    
    % smoothness term
    edgeWeights=[
        revindC(CL1) revindC(CL2) DL+1e-8 DL+1e-8;
        revindC(CU1) revindC(CU2) DU+1e-8 DU+1e-8
    ];

    %%  graph-cut labeling
    [~, labels] = graphCutMex(terminalWeights, edgeWeights); 
    
    As=A;  Bs=B; 
    As(ind(labels==1))=false;   % 
    Bs(ind(labels==0))=false;   % reference
    % possion image blending
    imgout = gradientBlend(warped_img1, As, warped_img2); 
    
    %% evaluate the current stitching seam
    B_contour = Bs(B_y0:B_y1,B_x0:B_x1);
    [hybrid_signal, boundarypts] = seamRefining(gray_cut1, gray_cut2, imgdif_cut, C_cut, B_contour, patchsize);
    Boundpts = boundarypts + repmat([B_y0-1,B_x0-1],length(boundarypts),1); % 全尺寸下缝合线坐标
    [extend_signal, extendpts] = signalExtend(hybrid_signal, Boundpts, As, Bs, C);
       
    %% 2nd-iteration for further refinement        
    % calculate a new stitching seam
    imgdif2 = imgdif;  ind_seam = (extendpts(:,2)-1)*sz1 + extendpts(:,1);
    imgdif2(ind_seam) = imgdif2(ind_seam).*(exp(sigma_ratio.*(extend_signal-signal_mu)));
    DL = (imgdif2(CL1) + imgdif2(CL2))./2;
    DU = (imgdif2(CU1) + imgdif2(CU2))./2;
    edgeWeights2=[
        revindC(CL1) revindC(CL2) DL+1e-8 DL+1e-8;
        revindC(CU1) revindC(CU2) DU+1e-8 DU+1e-8
    ];

    %% graph cut optimization
    [~, labels2] = graphCutMex(terminalWeights, edgeWeights2);  
    
    As=A;  Bs=B;
    As(ind(labels2==1))=false;   
    Bs(ind(labels2==0))=false;   
    
    final_As = As;  
    %% evaluate the current stitching seam
    B_contour = Bs(B_y0:B_y1,B_x0:B_x1); 
    [hybrid_signal2, boundarypts2] = seamRefining(gray_cut1, gray_cut2, imgdif_cut, C_cut, B_contour, patchsize);
    Boundpts2 = boundarypts2 + repmat([B_y0-1,B_x0-1], length(boundarypts2),1); % 全尺寸下缝合线坐标
    [extend_signal2, extendpts2] = signalExtend(hybrid_signal2, Boundpts2, As, Bs, C);
           
    %% iteration (while-loop) for seam refining
    end_seam = union(extendpts, extendpts2, 'rows');
    overlap_pts = setdiff(Boundpts2, extendpts, 'rows');
    k_seam = 3;  
    while length(overlap_pts)>10 && k_seam<=max_iterations  % change exceed 10 pixels
        ind_seam2 = (extendpts2(:,2)-1)*sz1 + extendpts2(:,1);
        imgdif3 = imgdif2;
        imgdif3(ind_seam2) = imgdif3(ind_seam2).*(exp(sigma_ratio.*(extend_signal2-signal_mu)));
        DL = (imgdif3(CL1) + imgdif3(CL2))./2;
        DU = (imgdif3(CU1) + imgdif3(CU2))./2;
        edgeWeights3=[
            revindC(CL1) revindC(CL2) DL+1e-8 DL+1e-8;
            revindC(CU1) revindC(CU2) DU+1e-8 DU+1e-8
        ];

        %% graph cut optimization
        [~, labels3] = graphCutMex(terminalWeights, edgeWeights3);  
    
        As=A;  Bs=B;
        As(ind(labels3==1))=false;   
        Bs(ind(labels3==0))=false;   
        final_As = As;  
        
       %% evaluate the current stitching seam
        B_contour = Bs(B_y0:B_y1,B_x0:B_x1);
        [hybrid_signal3, boundarypts3] = seamRefining(gray_cut1, gray_cut2, imgdif_cut, C_cut, B_contour, patchsize);
        Boundpts3 = boundarypts3 + repmat([B_y0-1,B_x0-1],length(boundarypts3),1); % 全尺寸下缝合线坐标
        [extend_signal3, extendpts3] = signalExtend(hybrid_signal3, Boundpts3, As, Bs, C);
        
        overlap_pts = setdiff(Boundpts3, end_seam, 'rows');
        end_seam = union(end_seam, extendpts3, 'rows');
        k_seam = k_seam + 1;
        extendpts2 = extendpts3;
        extend_signal2 = extend_signal3;
        imgdif2 = imgdif3;
    end

    
    final_out = gradientBlend(warped_img1, final_As, warped_img2);
    final_Bs = (A|B) & ~final_As;
    C_seam = imdilate(final_As, square_SE) & imdilate(final_Bs, square_SE) & C;
    final_seam = final_out;
    final_seam(cat(3, C_seam, C_seam, C_seam)) = [ones(sum(C_seam(:)),1); zeros(2*sum(C_seam(:)),1)];
    fprintf('final output comes from k_seam = %d\n', k_seam-1);
    figure,imshow(final_out);
    figure,imshow(final_seam);
      
    
end