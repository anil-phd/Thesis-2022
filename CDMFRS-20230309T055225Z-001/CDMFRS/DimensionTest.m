function dimvec = DimensionTest(j,k,inputD,theta1)         % checking dimension overlap between two Hyperboxes.
dimvec = false(1,inputD);
for i = 1:inputD       % J <- H1, K <- H2   j[1,i) minpoint  j[2,i) maxpoint
    isOverlapInDim = false;
    att = 1;
    if ((j(1,i) == j(2,i)) && (k(1,i) == k(2,i)) && k(1,i) == j(1,i))                           % both are point hyperbox
        isOverlapInDim = true;
    elseif( (j(1,i) == j(2,i)) && (k(1,i) ~= k(2,i)) )                       % one is point hyperbox
        if((k(1,i) <= j(1,i)) && (j(1,i) <= k(2,i)))
            isOverlapInDim = true;
        end
    elseif( (j(1,i) ~= j(2,i)) && (k(1,i) == k(2,i)) )                          % one is point hyperbox
        if((j(1,i) <= k(1,i)) && (k(1,i) <= j(2,i)))
            isOverlapInDim = true;
        end
    else
        if(j(1,i) < k(1,i) && k(1,i) < j(2,i) && j(2,i) < k(2,i))
            w = j(2,i) - k(1,i);
            att = (max(w/(j(2,i) - j(1,i)), w/(k(2,i) - k(1,i))));
            isOverlapInDim = true;
            %case 2
        elseif(k(1,i) < j(1,i) && j(1,i) < k(2,i) && k(2,i) < j(2,i))
            w = k(2,i) - j(1,i);
            att = (max(w/(j(2,i) - j(1,i)), w/(k(2,i) - k(1,i))));
            isOverlapInDim = true;
            %case 3
        elseif (j(1,i) < k(1,i) && k(1,i) < k(2,i) && k(2,i) < j(2,i))
            w = (k(2,i) - k(1,i));
            att = (max(w/(j(2,i) - j(1,i)), w/(k(2,i) - k(1,i))));
            isOverlapInDim = true;
            %case 4
        elseif (k(1,i) < j(1,i) && j(1,i) < j(2,i) && j(2,i) < k(2,i))
            w = (j(2,i) - j(1,i));
            att = (max(w/(j(2,i) - j(1,i)), w/(k(2,i) - k(1,i))));
            isOverlapInDim = true;
            %case 5
        elseif (j(1,i) == k(1,i) && k(1,i) < j(2,i) && j(2,i) < k(2,i))
            w = (j(2,i) - j(1,i));
            att = (max(w/(j(2,i) - j(1,i)), w/(k(2,i) - k(1,i))));
            isOverlapInDim = true;
            %case 6
        elseif (j(1,i) < k(1,i) && k(1,i) < j(2,i) && j(2,i) == k(2,i))
            w = (k(2,i) - k(1,i));
            att = (max(w/(j(2,i) - j(1,i)), w/(k(2,i) - k(1,i))));
            isOverlapInDim = true;
            %case 7
        elseif (k(1,i) == j(1,i) && j(1,i) < k(2,i) && k(2,i) < j(2,i))
            w = (k(2,i) - k(1,i));
            att = (max(w/(j(2,i) - j(1,i)), w/(k(2,i) - k(1,i))));
            isOverlapInDim = true;
            %case 8
        elseif (k(1,i) < j(1,i) && j(1,i) < k(2,i) && k(2,i) == j(2,i))
            w = (j(2,i) - j(1,i));
            att = (max(w/(j(2,i) - j(1,i)), w/(k(2,i) - k(1,i))));
            isOverlapInDim = true;
        end % end of inside else
    end %end of else
    
    if (~isOverlapInDim)
        dimvec(i) = 1;
    elseif (isOverlapInDim  && att < theta1)
        dimvec(i) = 1;
    end
end      % end of for loop of dimension
%dimvec = dimvec(dimvec ~= 0);
end
