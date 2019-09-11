function [ BoundaryPts ] = contourTracingofRight( B_seam )
% tracing the contour of the binary image£¬
% B_seam: binary image
% BoundaryPts: contour coordinates [rows, cols]
% the contour points are in white region and the white is on the right
% only consider the case that the seam begins on the left or top and ends on the right or bottom
    Movement = [0,1; 1,1; 1,0; 1,-1; 0,-1; -1,-1; -1,0; -1,1];
    % //eight directions£º1--E, 2--SE, 3--S, 4--SW, 5--W, 6--NW, 7--N, 8--NE
    [sz1,sz2] = size(B_seam);

    BoundaryPts = zeros(10000,2);
    NeedTracingFlag=false;
    EndFlag=false;
    BoundaryPtsNO = 1;
    % get the begining point and direction
    if(B_seam(1, 1)==0)	%first case: left is black, right is white
        for j=1:sz2
            if B_seam(1,j)==1
                NeedTracingFlag=true;
                break;
            end
        end	
            BoundaryPts(BoundaryPtsNO,1)=1;
            BoundaryPts(BoundaryPtsNO,2)=j;
            ClockDireaction=1;	
    else  %second case: top white, down black
        for i=1:sz1
            if  B_seam(i,1)==0
                NeedTracingFlag=true;
                break;
            end
        end	
            BoundaryPts(BoundaryPtsNO,1)=i-1;
            BoundaryPts(BoundaryPtsNO,2)=1;
            ClockDireaction=7;
    end

	BoundaryPtsNO = BoundaryPtsNO+1;

    if NeedTracingFlag		
        while (~EndFlag)
         for k=0:1:7
            tempi=BoundaryPts(BoundaryPtsNO-1,1)+Movement(mod(k+7+ClockDireaction,8)+1,1);
            tempj=BoundaryPts(BoundaryPtsNO-1,2)+Movement(mod(k+7+ClockDireaction,8)+1,2);
            if (tempi<1)
                EndFlag = false;
                continue;
            end 
            if (tempj<1) || (tempi>sz1) ||(tempj>sz2) 
                EndFlag=true;
                break;
            end
            if  B_seam(tempi,tempj)==0   %find the first black point in clockwise in the 8-neighborhood
                EndFlag=false;
                break;
            end
         end
            if ~EndFlag
                BoundaryPts(BoundaryPtsNO,1)=BoundaryPts(BoundaryPtsNO-1,1)+Movement(mod(k+ClockDireaction+6,8)+1,1);
                BoundaryPts(BoundaryPtsNO,2)=BoundaryPts(BoundaryPtsNO-1,2)+Movement(mod(k+ClockDireaction+6,8)+1,2);
                BoundaryPtsNO = BoundaryPtsNO+1;
                ClockDireaction=mod(k+ClockDireaction+2,8)+1;
            end
        end
    end
    
    BoundaryPts = BoundaryPts(1:BoundaryPtsNO-1,:);
    fprintf('Contour tracing finished! total %d pixels traced.\n', BoundaryPtsNO-1);

end
