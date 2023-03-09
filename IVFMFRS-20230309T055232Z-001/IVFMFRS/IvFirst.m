function [t_FM, t_DS, t_Red, Reduct, DM, r_c, HBS, HBS_In, HBS_cl] = IvFirst(DT, inputD, n_cls, gamma, theta)
tic;
[n_r,n_c] = size(DT);
v_c(1:(fix(n_r/2))) = 0;

a_s(1:n_cls) = 1;
n_eclass = cell(n_cls,1);
n_eclass(1:n_cls,1) = {v_c};

for z = 1:n_r
    ir = DT(z,n_c);
    n_eclass{ir}(a_s(ir)) = z;
    a_s(ir) = a_s(ir) + 1;
end

n_eclass = cellfun(@(x) x(x>0),n_eclass,'UniformOutput',false);

M = zeros(2,inputD);
hbo = cell(1,n_cls);
A = cell(1,70);
A(1:70) = {M};
hbo(1:n_cls) = {A};
r_c(1:n_cls) = 0;

clear A;

for v = 1:n_cls
    clfy(n_eclass{v},v);
end
t_FM = toc;

clear n_eclass;

tic;
t = 0;
lr = n_cls - 1;
for b = 1:lr
    t = t + r_c(b) * sum(r_c((b+1):n_cls));
end

rs = 1;
DS = zeros(t,inputD);
DM = zeros(t,inputD+4);
r_cc = [0 r_c];
for N = 1:(n_cls-1)
    for W = (N+1):n_cls
        for E = 1:(r_c(N))
            for Y = 1:(r_c(W))
                tt = DimensionTest(hbo{N}{E},hbo{W}{Y},inputD);   %make sure tt is vector
                DS(rs,:) = tt;
                DM(rs,5:(inputD+4)) = tt;
                DM(rs,1) = E + sum(r_cc(1:N));
                DM(rs,2) = N;                          % class H1
                DM(rs,3) = Y + sum(r_c(1:(W-1)));
                DM(rs,4) = W;                          % class H2
                rs = rs + 1;
            end
        end
    end
end
t_DS = toc;

clear tt;
tic;
Red = [];
Inp = 1:inputD;
[~,ll] = max(sum(DS));
Red = [Red ll];

rsum = arrayfun(@Smin,sum(DS,2));
tt = (DS(:,ll) == rsum);
DS = DS(~tt,:);
rsum(tt) = [];
rsum = rsum';

while(~isempty(DS))
    Mx = 0;
    MxI = [];
    Rt = setdiff(Inp,Red);
    index = 0;
    nvi = arrayfun(@Smin,sum(DS(:,Red),2));
    for K = Rt
        nv = arrayfun(@Smin,(nvi+DS(:,K)));
        nvv = sum(nv);
        if (nvv > Mx)
            MxI = nv;
            Mx = nvv;
            index = K;
        end
    end
    MxI = MxI';
    Red = [Red index];
    DS = DS(MxI ~= rsum,:);
    rsum(MxI == rsum) = [];
end
t_Red = toc;

Reduct = Red;
Hyp = sum(r_c);

HBS = cell(1,Hyp);           %collection of hyperbox cell
HBS_cl(1,Hyp) = 0;           %class of each hyperbox   %vector
HBS_In = cell(1,n_cls);      %Index of hyperbox in each class cell
m = 1;
for v = 1:n_cls
    HBS_In{v} = sum(r_cc(1:v))+1:sum(r_c(1:v));
    for r = 1:r_c(v)
        HBS{m} = hbo{v}{r};
        HBS_cl(m) = v;
        m = m+1;
    end
end

clear hbo;
clear DS;

    function clfy(dataR,cl)
        c_n = 1;
        q = 1;
        for p = 1:(length(dataR))
            l = DT(dataR(p),(1:inputD));
            isMember = false;
            if((c_n*q) >= (70*q))
                hbo{cl}((end+1):(end+70)) = {M};
                q = q + 1;
            end
            if (c_n == 1)
                hbo{cl}{c_n}(1,:) = l;
                hbo{cl}{c_n}(2,:) = l;
                r_c(cl) = 1;
                c_n = c_n +1;
            else
                em(1:r_c(cl)) = 0;
                for j = 1:r_c(cl)
                    result = (sum(max(0,(1-max(0,gamma*min(1,(hbo{cl}{j}(1,:) - l)))))) + sum(max(0,(1-max(0,gamma*min(1,l-(hbo{cl}{j}(2,:))))))));
                    result = result/(2*inputD);
                    if(result == 1)
                        isMember = true;
                        break
                    else
                        em(j) = result;
                    end
                end
                if(isMember ~= true)
                    [~,r_m] = sort(em,'descend');
                    for k = 1:r_c(cl)
                        hboxExpanded = r_m(k);
                        MaxV = max(hbo{cl}{hboxExpanded}(2,:),l);
                        MinV = min(hbo{cl}{hboxExpanded}(1,:),l);
                        threshold = sum(MaxV - MinV);
                        if((inputD * theta) >= threshold)
                            hbo{cl}{hboxExpanded}(2,:) = MaxV;
                            hbo{cl}{hboxExpanded}(1,:) = MinV;
                            isMember = true;
                            break
                        end
                    end
                end
                if(~isMember)
                    hbo{cl}{c_n}(1,:) = l;
                    hbo{cl}{c_n}(2,:) = l;
                    r_c(cl) = r_c(cl) + 1;
                    c_n = c_n + 1;
                end
            end
        end
    end
end
