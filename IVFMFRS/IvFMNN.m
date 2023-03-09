function [allU_FM, allU_DS, allU_Red, allU_r, Reduct, Hyp] = IvFMNN(U, inputD, n_cls, recordsperfold, dty)
allU_r = cell(1,10);
allU_FM = zeros(1,10);
allU_DS = zeros(1,10);
allU_Red = zeros(1,10);

gamma = 4;
theta = 0.3;

[t_FM, t_DS, t_Red, R, DM, r_c, HBS, HBS_In, HBS_Cl] = IvFirst(U{1}, inputD, n_cls, gamma, theta); %U1

allU_r{1} = R;
allU_FM(1) = t_FM;
allU_DS(1) = t_DS;
allU_Red(1) = t_Red;

M = zeros(2,inputD);    %empty hyperbox
HBSE = cell(1,recordsperfold);
V(1:recordsperfold) = 0;

ninp = inputD + 4;   %No. of column in FDM
Inp = 1:inputD;

%% Main Program of Incremental updation

for i=2:10
    tic;
    DTTrain = U{i};       % U2, U3, U4, ...., U10  eval(['U' num2str(i)])
    [dtx,~] = size(DTTrain);
    nr_c = r_c;
    noh = length(HBS);
    nob = noh+1;
    HBS = [HBS HBSE];
    HBS_flag(1:(noh+dtx)) = 0;
    HBS_Cl = [HBS_Cl V];
    
    %% Creating New Hyperboxes
    for x = 1:dtx
        Cl = DTTrain(x,dty);           %Class of object
        l = DTTrain(x,(1:inputD));     %Object
        isMember = false;
        em = [];
        em(1:r_c(Cl)) = 0;
        Im = HBS_In{Cl};
        for j = 1:r_c(Cl)
            Iv = Im(j);
            result = (sum(max(0,(1-max(0,gamma*min(1,(HBS{Iv}(1,:) - l)))))) + sum(max(0,(1-max(0,gamma*min(1,l-(HBS{Iv}(2,:))))))));
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
            for k = 1:r_c(Cl)
                hboxExpanded = Im(r_m(k));
                MaxV = max(HBS{hboxExpanded}(2,:),l);
                MinV = min(HBS{hboxExpanded}(1,:),l);
                threshold = sum(MaxV - MinV);
                if((inputD * theta) >= threshold)
                    HBS{hboxExpanded}(2,:) = MaxV;
                    HBS{hboxExpanded}(1,:) = MinV;
                    isMember = true;
                    HBS_flag(hboxExpanded) = 1;
                    break
                end
            end
        end
        if(~isMember)
            noh = noh + 1;
            HBS{noh} = M;
            HBS{noh}(1,:) = l;
            HBS{noh}(2,:) = l;
            r_c(Cl) = r_c(Cl) + 1;
            HBS_In{Cl} = [HBS_In{Cl} noh];
            HBS_Cl(noh) = Cl;
        end
    end
    nhy = noh-nob+1;         % Number of new hyperboxes
    Inhy = nob:noh;           % index of new hyperboxes
    HBS = HBS(1:noh);
    HBS_flag = HBS_flag(1:noh);
    HBS_Cl = HBS_Cl(1:noh);
    
    allU_FM(i) = toc;
    %% Update the Relative Fuzzy-Discernibility Matrix
    tic;
    Ii = [];
    In = find(HBS_flag(1:sum(nr_c)) == 1);   %Index number is hyperbox number
    if isempty(In) ~= 1
        for x = In
            DI = (find(x == DM(:,1)))';
            DI = setdiff(DI,Ii);
            for y = DI
                z = DM(y,3);
                TD = DimensionTest(HBS{x},HBS{z},inputD);
                if isequal(TD,DM(y,5:ninp))
                    DI = setdiff(DI,y);
                else
                    DM(y,5:ninp) = TD;
                end
            end
            Ii = [Ii DI];
            DI = (find(x == DM(:,3)))';
            DI = setdiff(DI,Ii);
            if ~isempty(DI)
                for y = DI
                    z = DM(y,1);
                    TD = DimensionTest(HBS{x},HBS{z},inputD);
                    if isequal(TD,DM(y,5:ninp))
                        DI = setdiff(DI,y);
                    else
                        DM(y,5:ninp) = TD;
                    end
                    %DM(y,5:ninp) = DimensionTest(HBS{x},HBS{z},inputD);
                end
                Ii = [Ii DI];
            end
        end
    end
    %% Updating the New Clauses FDM
    
    S = 0;
    for b = 1:(n_cls-1)
        S = S + (length(find(b == HBS_Cl(Inhy)))) * (length(find(b ~= HBS_Cl)));
    end
    
    [rdm,~] = size(DM);
    DM = [DM;zeros(S,ninp)];
    ordm = rdm+1;
    for I = Inhy
        for J = 1:noh
            if HBS_Cl(I) ~= HBS_Cl(J)
                rdm = rdm + 1;
                DM(rdm,5:ninp) = DimensionTest(HBS{I},HBS{J},inputD);
                DM(rdm,1) = J;            %need to be change
                DM(rdm,2) = HBS_Cl(J);
                DM(rdm,3) = I;
                DM(rdm,4) = HBS_Cl(I);
            end
        end
    end
    
    if nhy == 0
        De = Ii;
    else
        De = [Ii ordm:rdm];
    end
    allU_DS(i) = toc;
    
    tic;
    DS = DM(De,5:ninp);   %Subset of FDM (updated and new clauses)
    %% Check the Current Reduct is applicable to FDM or not
    
    flag = 0;
    sn = sum(arrayfun(@Smin,sum(DS(:,R),2)));  %conorm of all rows with R attributes
    snv = sum(arrayfun(@Smin,sum(DS,2)));      %conorm of all rows with all attributes
    if ~isequal(sn,snv)
        flag = 1;
    end
    
    %% Then find Reduct based on updated FDM using Foward selection and Backward elimination.
    
    %%%%%% Forward Selections %%%%%%%
    if flag == 1
        snw = (arrayfun(@Smin,sum(DS,2)))';
        while(~isempty(DS))
            Mx = 0;
            MxI = [];
            Rt = setdiff(Inp,R);
            index = 0;
            nvi = arrayfun(@Smin,sum(DS(:,R),2));
            for K = Rt
                %nv = arrayfun(@Smin,sum(DS(:,[R K]),2));
                nv = arrayfun(@Smin,(nvi+DS(:,K)));
                nvv = sum(nv);
                if (nvv > Mx)
                    MxI = nv;
                    Mx = nvv;
                    index = K;
                end
            end
            MxI = MxI';
            if index ~= 0
                R = [R index];
            end
            DS = DS(MxI~= snw,:);
            snw(MxI == snw) = [];
        end
        
        %%%% Backward Elimination %%%%%%%
        DY = DM(:,5:ninp);   % Updated FDM
        snw = sum(arrayfun(@Smin,sum(DY,2)));
        for inpp = R
            Red = setdiff(R,inpp);
            if ~isempty(Red)
                sn = sum(arrayfun(@Smin,sum(DY(:,Red),2)));
                if isequal(sn,snw)
                    R = Red;
                end
            end
        end
        clear DY
    end
    allU_r{i} = R;
    allU_Red(i) = toc;
end
%disp('Main Reduct');
Reduct = R;
Hyp = sum(r_c);
end
