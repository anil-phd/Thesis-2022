function dimvec = DimensionTest(j,k,inputD)  % checking dimension overlap between two Hyperboxes.
dimvec(1:inputD) = 0;
for i = 1:inputD              % J <- H1, K <- H2   j[1,i) minpoint  j[2,i) maxpoint
    DSimR = 0;
    isOverlapInDim = false;
    if ((j(1,i) == j(2,i)) && (k(1,i) == k(2,i)) && k(1,i) == j(1,i))                           % both are point hyperbox
        isOverlapInDim = true;
    elseif ( (j(1,i) == j(2,i)) && (k(1,i) ~= k(2,i)) )                       % one is point hyperbox
        if ((k(1,i) <= j(1,i)) && (j(1,i) <= k(2,i)))
            isOverlapInDim = true;
        end
    elseif ( (j(1,i) ~= j(2,i)) && (k(1,i) == k(2,i)) )                          % one is point hyperbox
        if ((j(1,i) <= k(1,i)) && (k(1,i) <= j(2,i)))
            isOverlapInDim = true;
        end
    elseif (j(1,i) < k(1,i) && k(1,i) < j(2,i) && j(2,i) < k(2,i))
        Ov_r = j(2,i) - k(1,i);
        lpt =  (j(2,i) - j(1,i)) - Ov_r;
        rpt =  (k(2,i) - k(1,i)) - Ov_r;
        DSimR = 1 - (Ov_r / (Ov_r + lpt + rpt));
        isOverlapInDim = true;
        %case 2
    elseif (k(1,i) < j(1,i) && j(1,i) < k(2,i) && k(2,i) < j(2,i))
        Ov_r = k(2,i) - j(1,i);
        lpt = (k(2,i) - k(1,i)) - Ov_r;
        rpt =  (j(2,i) - j(1,i)) - Ov_r;
        DSimR = 1 - (Ov_r / (Ov_r + lpt + rpt));
        isOverlapInDim = true;
        %case 3
    elseif (j(1,i) < k(1,i) && k(1,i) < k(2,i) && k(2,i) < j(2,i))
        DSimR = 0;
        isOverlapInDim = true;
        %case 4
    elseif (k(1,i) < j(1,i) && j(1,i) < j(2,i) && j(2,i) < k(2,i))
        DSimR = 0;
        isOverlapInDim = true;
        %case 5
    elseif (j(1,i) == k(1,i) && k(1,i) < j(2,i) && j(2,i) < k(2,i))
        DSimR = 0;
        isOverlapInDim = true;
        %case 6
    elseif (j(1,i) < k(1,i) && k(1,i) < j(2,i) && j(2,i) == k(2,i))
        DSimR = 0;
        isOverlapInDim = true;
        %case 7
    elseif (k(1,i) == j(1,i) && j(1,i) < k(2,i) && k(2,i) < j(2,i))
        DSimR = 0;
        isOverlapInDim = true;
        %case 8
    elseif (k(1,i) < j(1,i) && j(1,i) < k(2,i) && k(2,i) == j(2,i))
        DSimR = 0;
        isOverlapInDim = true;
    end % end of inside else
    
    if (~isOverlapInDim)
        dimvec(i) = 1;
    else
        dimvec(i) = DSimR;
    end
end
end