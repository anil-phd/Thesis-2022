function [Reduct, SumHyp] = CDMFMFRS(DTTrain, Theta, Gamma)
    [dtx,dty] = size(DTTrain);
    Theta1 = 0.1;
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
    end 

    clear n_eclass;

    t = 0;
    lr = n_cls - 1;
    for b = 1:lr
        t = t + HypEachClass(b) * sum(HypEachClass((b+1):n_cls));
    end
%disp(t);

    rs = 1;
    DM = false(t,inputD);
    for N = 1:(n_cls-1)
        for W = (N+1):n_cls
            for E = 1:(HypEachClass(N))
                for Y = 1:(HypEachClass(W))
                    tt = DimensionTest(HBS{N}{E}, HBS{W}{Y}, inputD, Theta1);   %make sure tt is a vector
                    DM(rs,:) = tt; 
                    rs = rs + 1;
                end
            end
        end
    end

    clear HBS;
    %clear HypEachClass

    Re(1:inputD) = 0;
    r = 1;
    l = sum(DM);

    while (sum(l) ~= 0)
        [~,ll] = max(l);
        Re(r) = ll;
        DM = DM(DM(:,ll) ~= 1,:);
        r = r + 1;
        [dx,~] = size(DM);
        if(dx == 0)
            break;
        end
        if(dx == 1)
            l = DM;
        else
            l = sum(DM);
        end
    end

    Reduct = Re(Re~=0);
    SumHyp = sum(HypEachClass);
end
