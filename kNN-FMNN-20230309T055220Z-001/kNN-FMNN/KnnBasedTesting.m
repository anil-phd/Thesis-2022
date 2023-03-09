function [Accuracy] = KnnBasedTesting(DTTrain, DTTest, inputD, n_cls,  HypEachClass, HBS, HbObjIndex, Gamma)
    [dtx, dty] = size(DTTest);
    acc(1:dtx) = 0;
    HypTotal = sum(HypEachClass);
    for Input = 1:dtx
        Memb(1:HypTotal) = 0;
        Cls(1:HypTotal) = 0;
        HypNum(1:HypTotal) = 0;
        Index = 1;
        TestData = DTTest(Input,(1:inputD));
        for Class = 1:n_cls
            for H = 1:HypEachClass(Class)
                result = (sum(max(0,(1-max(0,Gamma*min(1,(HBS{Class}{H}(1,:)-TestData)))))) + sum(max(0,(1-max(0,Gamma*min(1,TestData-(HBS{Class}{H}(2,:)))))))); 
                Memb(Index) = result/(2*inputD);
                Cls(Index) = Class;
                HypNum(Index) = H;
                Index = Index+1;
            end
        end        
        tt = find(Memb == 1);
        if (length(tt) > 1)             % Overlap Region
            kk = [];
            for a = tt
                kk = [kk HbObjIndex{Cls(a)}{HypNum(a)}];
            end
            %disp('bell1');
            TrainData = DTTrain(kk,1:inputD);
            TrainClass = DTTrain(kk,dty);
            Mdl = fitcknn(TrainData,TrainClass,'NumNeighbors',3);
            acc(Input) =  predict(Mdl,TestData);
        elseif (length(tt) == 1)
            acc(Input) = Cls(tt);
        else
            [~,g] = max(Memb);
            acc(Input) = Cls(g);
        end
    end
    %disp(acc);
    T = DTTest(:,dty);
    T = T';
    Accuracy = (sum(acc == T)/dtx)*100;
    %disp(Accuracy);
end