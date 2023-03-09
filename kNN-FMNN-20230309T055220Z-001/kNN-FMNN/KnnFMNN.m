function [Accuracy, Time, SumHyp] =  KnnFMNN(DTTrain, DTTest, Theta, Gamma)
    tic;
    [dtx,dty] = size(DTTrain);
    inputD = dty - 1;
    n_cls = length(unique(DTTrain(:,dty)));
    v_c(1:(fix(dtx/2))) = 0;
    a_s(1:n_cls) = 1;
    n_eclass = cell(n_cls,1);
    n_eclass(1:n_cls,1) = {v_c};

    for z = 1:dtx
        ir = DTTrain(z,dty);
        n_eclass{ir}(a_s(ir)) = z;
        a_s(ir) = a_s(ir) + 1;
    end

    n_eclass = cellfun(@(x) x(x>0),n_eclass,'UniformOutput',false);
    M = zeros(2,inputD);
    HBS = cell(1,n_cls);         % Number of Hyperboxes in each classes
    A = cell(1,300);
    A(1:300) = {M};
    HBS(1:n_cls) = {A};
    HbObjIndex = cell(1,n_cls);
    B = cell(1,300);
    p(1:(fix(dtx/4))) = 0;
    B(1:300) = {p};
    HbObjIndex(1:n_cls) = {B};   % Saving object index in each hyperboxes
    HypEachClass(1:n_cls) = 0;

    %% calling hypCreation function for each class
    for iter = 1:n_cls
        [HBS, HbObjIndex, HypEachClass]= HypCreation(DTTrain, n_eclass{iter}, HBS, HbObjIndex, HypEachClass, iter, Theta, Gamma, inputD);
        HBS{iter} = HBS{iter}(1:HypEachClass(iter));
        HbObjIndex{iter} = HbObjIndex{iter}(1:HypEachClass(iter));
        HbObjIndex{iter} =  cellfun(@(x) x(x>0),HbObjIndex{iter},'UniformOutput',false);
    end
    
    Time = toc;
    SumHyp = sum(HypEachClass);

    %% testing error rate
    %disp('KnnBasedTesting')
    [Accuracy] = KnnBasedTesting(DTTrain, DTTest, inputD, n_cls,  HypEachClass, HBS, HbObjIndex, Gamma);
end

