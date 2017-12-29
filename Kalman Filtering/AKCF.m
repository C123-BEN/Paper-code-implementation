%Alam S M S, Natarajan B, Pahwa A. Agent Based Optimally Weighted Kalman Consensus Filter over a Lossy Network[C]// IEEE %Global Communications Conference. IEEE, 2015:1-6.
%By xuelang-wang

close all
clear
clc
%%%%%%%%%%%%%%%%%%%%%��ʼ�����ڵ㣨SYS��
F = [0.95 0  0;1 0.9 0;1 1 0.8];%ȫ��ת�ƾ���
Q = diag([1.8 0.9 0.5]);%ȫ��ϵͳ����
T = {[1 0 0;0 1 0];[0 1 0;0 0 1]};%��ȡ�ڵ�ת�ƾ���
mu = [10 5 8]';%��ʼ״̬����
sigma = diag([0.8 0.2 0.5]);%��ʼ״̬�������
H = {[2,0];[3,0]};%�ڵ��������
R = {0.0648;0.05};%�ڵ��������
S = {[0 1];[1 0]};%��ȡ�������
OS = {[0 1]';[1 0]'};%�޸��������
U = {[1 0];[0 1]};%��ȡ���������
OU = {[1 0]';[0 1]'};%�޸����������
P = {0 1;1 0};%�����źŽڵ�Ĺ�����ȡ����
L = {0 1;1 0};%�����źŽڵ�Ĺ�����ȡ����
for i =1:2
    Fk{i,1} = T{i,1}*F*T{i,1}';%�ڵ�ת�ƾ���
    Qk{i,1} = T{i,1}*Q*T{i,1}';%�ڵ�ϵͳ���
end
%����AF����
for i=1:2
    for j = 1:2
        if j==i
            AF{i,j}=0;
            for k=1:2
                AF{i,j}=OS{i,1}*L{k,i}*S{i,1}*Fk{i,1}+AF{i,j};
            end
        else
            AF{i,j}=-OS{i,1}*P{j,i}*S{j,1}*Fk{j,1};
        end
    end
end
AF = cell2mat(AF);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%Algorithm AKCF
t = 31;%��������
N = 1000;%Monte Carlo ʵ�����
E = [0.2;0.34];%һ����ˮƽ
for n=1:2
    for k =1:N;
        X_real(:,1) = mu;%ȫ��״̬��ʵֵ
        for i = 1:2  
            x_real{i,1} = T{i,1}*X_real(:,1);%�ڵ�״̬��ʵֵ
            x_est{i,1} = T{i,1}*X_real(:,1);%�ڵ�״̬����ֵ
            M_est{i,1} = T{i,1}*sigma*T{i,1}';%�ڵ�������
        end
        for j = 1:t
            X_real(:,j+1) = F*X_real(:,j)+diag(normrnd(0,Q,3,3));%ȫ��״̬��ʵ����
            for i = 1:2
                x_real{i,j+1} = T{i,1}*X_real(:,j+1);%��ȡ�ڵ����״̬
%                 x_real{i,j+1} = Fk{i,1}*x_real{i,j}+diag(normrnd(0,Qk{i,1},2,2));
                y{i,j+1} = H{i,1}*x_real{i,j+1}+normrnd(0,R{i,1},1,1);%�۲�ֵ
                x_pre{i,1} = Fk{i,1}*x_est{i,j};%һ��Ԥ��
                M_pre{i,1} = Fk{i,1}*M_est{i,j}*Fk{i,1}'+Qk{i,1};%Ԥ��������
                K{i,1} = M_pre{i,1}*H{i,1}'*inv(H{i,1}*M_pre{i,1}*H{i,1}'+R{i,1});%�˲�����
                M_est{i,j+1} = M_pre{i,1}-K{i,1}*H{i,1}*M_pre{i,1};%�ڵ����״̬���
                b{i,j+1} = x_pre{i,1}+K{i,1}*(y{i,j+1}-H{i,1}*x_pre{i,1});%�ڵ����״̬
                W{i,j+1} = E(n,1)*(OS{i,1})'*M_pre{i,1}*(inv(Fk{i,1}))'*OS{i,1};%%����Ȩ��
                C{i,j+1} = Fk{i,1}-K{i,1}*H{i,1}*Fk{i,1};
                Dk{i,j+1} = inv(C{i,j+1})*M_est{i,j+1}*inv(C{i,j+1})';
                G{i,j+1} = inv(M_est{i,j})-inv(Dk{i,j+1});
                lambda(i,1)=max(eig(G{i,j+1}));
            end
            Dt{1,j+1}=blkdiag(Dk{1,j+1},Dk{2,j+1});
            lambda_g=max(lambda);
            lambda_d=max(eig(AF'*Dt{1,j+1}*AF));
            lambda_gd(1,j+1)=sqrt(lambda_g/lambda_d);
            for i =1:2
                switch i
                    case 1
                        x_est_s{i,j+1} = S{i,1}*b{i,j+1}+W{i,j+1}*(P{2,1}*S{2,1}*x_pre{2,1}-L{2,1}*S{1,1}*x_pre{1,1});
                    case 2
                        x_est_s{i,j+1} = S{i,1}*b{i,j+1}+W{i,j+1}*(P{1,2}*S{1,1}*x_pre{1,1}-L{1,2}*S{2,1}*x_pre{2,1});
                end
                x_est{i,j+1} = OS{i,1}*x_est_s{i,j+1}+OU{i,1}*U{i,1}*b{i,j+1};
                e{i,j+1} = x_est{i,j+1}-T{i,1}*X_real(:,j+1);
%                 e{i,j+1} = x_est{i,j+1}-x_real{i,j+1};
            end
            MSD(k,j+1) = e{1,j+1}'*e{1,j+1}+e{2,j+1}'*e{2,j+1};
        end
        lambda_up(1,k) = min(lambda_gd(1,3:t+1));
    end
    TMSD=sum(MSD(:,:))/1000;
    TMSD(1,1) = 1;
    if n == 1
        semilogy(1:t+1,TMSD,'vb-');
    else
        semilogy(1:t+1,TMSD,'^r-');
    end
    hold on
end
 axis([0 t+1 1 1e6]);
 grid on;
 legend('\epsilon = 0.2','\epsilon = 0.34');
 xlabel('Time Index t');
 ylabel('TMSD_t');
 title('SYS in Perfect Network(\rho = 0)')





