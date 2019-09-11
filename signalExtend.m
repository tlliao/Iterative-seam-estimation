function [ extend_signal, extend_seam ] = signalExtend( seam_signal, seam_pts, As, Bs, C )
% extend current seam evaluation to a banding area

SE = strel('square', 10); 

Cs_seam = imdilate(As, SE) & imdilate(Bs, SE) & C;
ind_seam = find(Cs_seam);
[m, n] = ind2sub(size(C), ind_seam);
extend_seam = [m, n];

dist_seam = pdist2(extend_seam,  seam_pts);
[~, ind_d] = min(dist_seam, [], 2);

extend_signal = seam_signal(ind_d);

end

