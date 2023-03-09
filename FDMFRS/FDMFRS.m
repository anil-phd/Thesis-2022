function [Reduct, SumHyp] = FDMFRS(DTTrain, Theta, Gamma)
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
    end 

    clear n_eclass;

    t = 0;
    lr = n_cls - 1;
    for b = 1:lr
        t = t + HypEachClass(b) * sum(HypEachClass((b+1):n_cls));
    end

    %disp(t);

    rs = 1;
    DM = zeros(t,inputD);
    for N = 1:(n_cls-1)
        for W = (N+1):n_cls
            for E = 1:(HypEachClass(N))
                for Y = 1:(HypEachClass(W))
                    tt = DimensionTest(HBS{N}{E}, HBS{W}{Y}, inputD);   %make sure tt is vector
                    DM(rs,:) = tt;
                    rs = rs + 1;
                end
            end
        end
    end

    clear HBS;
    %clear HypEachClass

    Red = [];
    Inp = 1:inputD;
    l = sum(DM);
    [~,ll] = max(l);
    Red = [Red ll];

    snv = arrayfun(@Smin,sum(DM,2));
    tt = (DM(:,ll) == snv);
    DM = DM(~tt,:);
    snv(tt) = [];
    snv = snv';

    while(~isempty(DM))
        Mx = 0;
        MxI = [];
        Rt = setdiff(Inp,Red);
        index = 0;
        for K = Rt
            nv = arrayfun(@Smin,sum(DM(:,[Red K]),2));
            nvv = sum(nv);
            if (nvv > Mx)
                MxI = nv;
                Mx = nvv;
                index = K;
            end
        end
        MxI = MxI';
        Red = [Red index];
        DM = DM(MxI~= snv,:);
        snv(MxI == snv) = [];
    end

    Reduct =  Red;
    SumHyp = sum(HypEachClass);

end
