function DFE()
% Networked fusion estimation with bounded noise----2017
% author��Bo Chen, et. al.
% Reference��Algorithm 1
% By: xuelang-wang

    L = 2; %����������
    C(:,:,1) = [0.5 1 0 0;
          0 0 0.9 0.6];
    C(:,:,2) = [0.9 0.8 0 0;
          0 0 0.5 1];
    B(:,:,1) = [0.5;0.7];
    B(:,:,2) = [0.7;0.5];

    D(1,1) = 0.1;
    D(2,1) = 0.2;
    n = 4;
    
    r = zeros(L,1);   %��������
    r(1,1) = 2;
    r(2,1) = 2;
    deta = zeros(L,1);%�����������
    for i = 1:L
        deta(i,1) = nchoosek(n,r(i,1));
    end
    ESR = zeros(L,1);%������
    ESR(1,1) = 0.1;
    ESR(2,1) = 0.1;
    p = zeros(6,2);%��ϸ���
    p(1,1) = 0.1;
    p(2,1) = 0.2;
    p(3,1) = 0.1;
    p(4,1) = 0.3;
    p(5,1) = 0.1;
    p(6,1) = 0.1;
    p(1,2) = 0.2;
    p(2,2) = 0;
    p(3,2) = 0.3;
    p(4,2) = 0.2;
    p(5,2) = 0;
    p(6,2) = 0.2;
 
    mu = zeros(L,1);
    mu(1,1) = 0.9;
    mu(2,1) = 0.9;
    alpha = 2.6;
    
    steps = 200;
    x = zeros(4,steps);
    x_est = zeros(4,steps);
    
    x_est_i = zeros(4,2,steps);
    x_c_i = zeros(4,2,steps);
    x0 = [0,0,0,0];
    x(:,1) = x0;
    x_est(:,1) = x0;
    x_est_i(:,1,1) = x0;
    x_est_i(:,2,1) = x0;
    x_c_i(:,1,1) = x0;
    x_c_i(:,2,1) = x0;
    

 
    for step = 1:steps-1
        H =[];
        Af=[];
        AL=[];
        Gf=[];
        Q =[];

        f = 0.9 + 0.1*sin(step);   % f����[0.8,1]
        A = [1 f 0 0;
            0 1 0 0;
            0 0 1 f;
            0 0 0 1]; 
        gama = [f*f/2;f;f*f/2;f];
        
        G = [gama zeros(size(gama,1),1)];
        BL = repmat(G,L,1);
        w = 2*rand() - 1;%��������
        
        x(:,step+1) = A*x(:,step)+gama*w;
        
        for k = 1:L
            v = rand() - 0.5;%��������
            y = C(:,:,k)*x(:,step) + B(:,:,k)*v;%����
            Ki = LuanbogerGain(A,gama,C(:,:,k),B(:,:,k),mu(k,1));%��������
            x_est_i(:,k,step+1) = A*x_est_i(:,k,step) + Ki*(y - C(:,:,k)*x_est_i(:,k,step));%Eq.4
            [Hi,Qi] = GetH(n,r(k,1),p(:,k));
            H = blkdiag(H,Hi);
            Afi = A - Ki*C(:,:,k);
            Gi = [zeros(size(B(:,:,k),1),1) B(:,:,k)];
            Gfi = G - Ki*Gi;
            Gf = [Gf;Gfi];
            Af = blkdiag(Af,Afi);
            AL = blkdiag(AL,A);
            Q =[Q;Qi*D(k,1)];
            zeta0 = randn(1);
            zeta = 0.1*sin(0.2*zeta0);
            x_c_i(:,k,step+1) = (eye(n,n) - Hi)*A*x_c_i(:,k,step) + Hi*x_est_i(:,k,step+1) + Qi*D(k,1)*zeta;%Eq. 12
        end

        Gm = H*Gf+(eye(size(H,1)) - H)*BL;
        W = GetWeight(H,Af,AL,Gm,Q,alpha,L);%����Ȩ��
        x_est(:,step+1) = W*[x_c_i(:,1,step+1);x_c_i(:,2,step+1)];
    end

    close all
    figure
    hold on
%     for i = 1:4
%         subplot(2,2,i);
%         plot(1:steps,x(i,:),'-b',1:steps,x_est(i,:),'-.b');
%         legend(['x_',num2str(i)],['DFE for x_',num2str(i)]);
%         xlabel('t/step')
%     end
    
    subplot(2,2,1);
    plot(160:steps,x(1,160:steps),'-b',160:steps,x_est(1,160:steps),'-.g');
    legend(['x_',num2str(i)],['DFE for x_',num2str(i)]);
    xlabel('t/step')
    subplot(2,2,2);
    plot(50:steps,x(2,50:steps),'-b',50:steps,x_est(2,50:steps),'-.g');
    legend(['x_',num2str(2)],['DFE for x_',num2str(2)]);
    xlabel('t/step')
    subplot(2,2,3);
    i = 3;
    plot(160:steps,x(i,160:steps),'-b',160:steps,x_est(i,160:steps),'-.g');
    legend(['x_',num2str(i)],['DFE for x_',num2str(i)]);
    xlabel('t/step')
    subplot(2,2,4);
    i = 4;
    plot(50:steps,x(i,50:steps),'-b',50:steps,x_est(i,50:steps),'-.g');
    legend(['x_',num2str(i)],['DFE for x_',num2str(i)]);
    xlabel('t/step')

end

function K = LuanbogerGain(A,B,Ci,Bi,ui)
% �������������棨���ŵģ�
% �ο�����  Networked Fusion Estimation With Bounded Noises.pdf
% x(t + 1) = A(t)x(t) + B(t)w(t)                            
% yi(t) = Ci(t)x(t) + Bi(t)v(t)(i = 1, . . . , L)              
% x^i(t + 1) = A(t)x^i(t) + Ki(t)(yi(t) - Ci(t)*x^i(t)) 
% ʵ�������ж���1
% Theorem 1: For a given ��i(0 < ��i < 1), the optimal estimator gain
%           Ki(t) can be obtained by solving the following convex optimization
% problem:      min                     ��i��i1(t) + (1-��i)��i2(t)
%     P i (t)> 0,K i (t),�� i 1 (t),�� i 2 (t)
% 
% s.t. :[-I A(t)-Ki(t)Ci(t) G(t)-Ki(t)Gi(t);
%         *      Pi(t)              0;
%         *       *            -��i2(t)I   ] < 0
% 
%         Pi(t)-��i1(t)I< 0
%         0 < ��i1(t) < 1
% G(t) = [B(t) 0], Gi(t) = [0 Bi(t)].
    if nargin == 0
        clear
        clc
        fprintf('ִ�������ϵ�һ������');
        f = 1;
        A = [1 f 0 0;
            0 1 0 0;
            0 0 1 f;
            0 0 0 1]; 
        B = [f*f/2;f;f*f/2;f];
        Ci= [0.5 1 0 0;
            0 0 0.9 0.6];
        Bi = [0.5;0.7];
        ui = 0.9;
    end


    n = size(A,1);
    m = size(B,2);
    nc = size(Ci,1);
    mb = size(Bi,2);
    G = [B zeros(n,mb)];
    Gi = [zeros(nc,m) Bi];
    setlmis([]);
    Ki=lmivar(2,[n,nc]);
    Pi=lmivar(1,[n,1]);
    Xi1=lmivar(1,[1,0]);
    Xi2=lmivar(1,[1,0]);

    lmiterm([1 1 1 0],-eye(n));
    lmiterm([1 1 2 0],A);
    lmiterm([1 1 2 Ki],-1,Ci);
    lmiterm([1 1 3 0],G);
    lmiterm([1 1 3 Ki],-1,Gi);
    lmiterm([1,2,2,Pi],-1,1);
    lmiterm([1 3 3 Xi2],-1,eye(m+mb));
    lmiterm([2 1 1 Pi],1,1);
    lmiterm([2 1 1 Xi1],-1,eye(n));
    lmiterm([3,1,1,Xi1],1,1);
    lmiterm([-3,1,1,0],1);
    lmiterm([-4,1,1,Xi1],1,1);
    lmiterm([-5,1,1,Pi],1,1);
    lmisys=getlmis;
    nvar=decnbr(lmisys);              %���LMIϵͳ�о��߱���������
    c=zeros(nvar,1);
    c(nvar-1,1)=ui;
    c(nvar,1)=1-ui;
    options=[0 0 0 0 0];
    [copt,xopt]=mincx(lmisys,c,options);   %��С��Լ��Ŀ��,c��ʾԼ��Ŀ�� copt��ʹȫ����С�Ľ�
    K = dec2mat(lmisys,xopt,Ki);
end

% function [p,amass] = GetP(n,r,ESR,index,k)
%%% ѡ��������㶨��2��������
%     %index = 0  ���ĸ���
%     %index = 1  ���ȷֲ�
%     %index = 2  ����ֲ�
%     deta = nchoosek(n,r);
%     p = zeros(deta,1);%ÿ�������ÿ����ϵĸ��ʣ�
%     amass = zeros(deta,1);%�ۻ�����
%     if(nargin == 5 && index == 0)
%         if(k == 1)
%             p(1,1) = 0.1;
%             p(2,1) = 0.2;
%             p(3,1) = 0.1;
%             p(4,1) = 0.3;
%             p(5,1) = 0.1;
%             p(6,1) = 0.1;
%         elseif(k == 2)
%             p(1,1) = 0.2;
%             p(2,1) = 0;
%             p(3,1) = 0.3;
%             p(4,1) = 0.2;
%             p(5,1) = 0;
%             p(6,1) = 0.2;
%         end
%         amass(1,1) = p(1,1);
%         for i = 2:deta
%             amass(i,1) = amass(i-1,1) + p(i,1);
%         end
%     end
%     if(index == 1)
%         p = (1-ESR)/deta*ones(deta,1);
%         for i = 1:deta
%             amass(i,1) = i*(1-ESR)/deta;
%         end
%     elseif(index == 2)
%         for i = 1:deta
%             if(i == 1)
%                 p(i,1) = (1 - ESR)*rand();
%                 amass(i,1) = p(i,1);
%             elseif(i < deta)
%                 p(i,1) = (1 - ESR - amass(i - 1,1)) * rand();
%                 amass(i,1) = amass(i - 1) + p(i,1);
%             else
%                 p(i,1) = 1 - ESR - amass(i-1,1);
%                 amass(i,1) = 1 - ESR;
%             end
%         end
%     end     
% end

function [H,Q] = GetH(n,r,p)
    %n��״̬��ά��
    %r: �������Ƶ��´����״̬ά������
    %ESR��������
    deta = nchoosek(n,r); %��n��ѡr���������
    %ʹ�þ��ȷֲ���ȷ������ÿ������ȸ��ʷ�����
    sigma = zeros(deta,1);
    amass = zeros(deta,1);%�ۻ�����

    amass(1,1) = p(1,1);
    for i = 2:deta
        amass(i,1) = amass(i-1,1) + p(i,1);
    end
    temp = rand();%����һ�������
    for i=1:deta
        if(temp < amass(i,1))
            sigma(i,1) = 1;
            break;
        end
    end
    H = zeros(n,n);
    Hi = zeros(n,n,deta);
    vec = zeros(n,1);
    for i = 1:n
        vec(i,1) = i;
    end
    Comb = nchoosek(vec,r);%������
    for i = 1:deta
        tp = zeros(n,1);
        tp(Comb(i,:)) = 1;
        Hi(:,:,i) = diag(tp);%ÿ��������Ӧ��Hi
        H = H + sigma(i,1)*Hi(:,:,i);%(Eq. 13)
    end
    Q = diag(H);
end

function W = GetWeight(H,Af,AL,Gm,Q,alpha,L)
    n = size(H,1)/L;%״̬ά��
    W = [];
    sum = 0;
    for i = 1:L-1
        temp = sdpvar(n,n,'full');
        W = [W,temp];
        sum = sum + temp;
    end
    W = [W,eye(n,n)-sum];
    A12 = [W*H*Af, W*(eye(size(H,1))-H)*AL];
    A13 = [W*Gm, -W*Q];
    
    chi = sdpvar(1,1);
    omega = sdpvar(size(Af,2)*2,size(Af,2)*2);

    P = [-eye(n,n), A12, A13;
        zeros(size(Af,2)*2,n),-omega, zeros(size(Af,2)*2,size(Gm,2)+size(Q,2));
        zeros(size(Gm,2)+size(Q,2),n), zeros(size(Gm,2)+size(Q,2),size(Af,2)*2), -chi*eye(size(Gm,2)+size(Q,2))];
    F = [P < 0,omega > 0,omega - alpha*eye(size(Af,2)*2) < 0];
    
    s = solvesdp(F,chi);
    W = double(W);
end
