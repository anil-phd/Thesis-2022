function [HBS, HbObjIndex, HypEachClass] = HypCreation(DTTrain, dataR, HBS, HbObjIndex, HypEachClass, Class, Theta, Gamma, inputD)
    NumOfHyp = 1;
    ExceedHypNums = 1;
    for Input = dataR
        InputData = DTTrain(Input,(1:inputD));
        isMember = false;
        if((NumOfHyp*ExceedHypNums) >= (300*ExceedHypNums))
            HBS{Class}((end+1):(end+300)) = {M};
            ExceedHypNums = ExceedHypNums + 1;
        end
        if (NumOfHyp == 1)
            HBS{Class}{NumOfHyp}(1,:) = InputData;
            HBS{Class}{NumOfHyp}(2,:) = InputData;
            HypEachClass(Class) = 1;
            NumOfHyp = NumOfHyp +1;
        else
            HypMembValues(1:HypEachClass(Class)) = 0;
            for HbIndex = 1:HypEachClass(Class)
                result = (sum(max(0,(1-max(0,Gamma*min(1,(HBS{Class}{HbIndex}(1,:) - InputData)))))) + sum(max(0,(1-max(0,Gamma*min(1,InputData-(HBS{Class}{HbIndex}(2,:))))))));
                result = result/(2*inputD);
                if(result == 1)
                    isMember = true;
                    break;
                else
                    HypMembValues(HbIndex) = result;
                end
            end
            if(isMember ~= true)
                [~,r_m] = sort(HypMembValues,'descend');
                for k = 1:HypEachClass(Class)
                    hboxExpanded = r_m(k);
                    MaxV = max(HBS{Class}{hboxExpanded}(2,:),InputData);
                    MinV = min(HBS{Class}{hboxExpanded}(1,:),InputData);
                    threshold = sum(MaxV - MinV);
                    if((inputD * Theta) >= threshold)
                        HBS{Class}{hboxExpanded}(2,:) = MaxV;
                        HBS{Class}{hboxExpanded}(1,:) = MinV;
                        isMember = true;
                        break;
                    end
                end
            end
            if (~isMember)
                HBS{Class}{NumOfHyp}(1,:) = InputData;
                HBS{Class}{NumOfHyp}(2,:) = InputData;
                HypEachClass(Class) = HypEachClass(Class) + 1;
                NumOfHyp = NumOfHyp + 1;

            end
        end
    end
end