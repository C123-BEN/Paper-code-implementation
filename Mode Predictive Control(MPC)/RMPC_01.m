close all
clear
clc
A=[1 1;0 1];
B=[0.5 1]';
Q=eye(2);
R=0.01;
% X = Polyhedron('A',[0 1],'b',2);
X = Polyhedron('lb',[-inf;-inf],'ub',[inf;2]);
U = Polyhedron('lb',-1,'ub',1);
W = Polyhedron('lb',[-0.1;-0.1],'ub',[0.1;0.1]);
N = 9;
%�ն˳ͷ�Ȩ�ؼ���Ӧ����K
model1 = LTISystem('A',A,'B',B);
model1.x.penalty = QuadFunction(Q);
model1.u.penalty = QuadFunction(R);
S = model1.LQRSet();%%%��Լ��ʱ�ն�Լ��(Xf)
K = model1.LQRGain();%%��Լ��ʱ�����棨K��
P = model1.LQRPenalty();%%%��Ӧ�ͷ�Ȩ��


AK = A+B*K;
% % %%%Ѱ��s,a���Ա��ҵ����伯Z�Ľ��ƽ�
% % figure
% % W=[-0.1 -0.1;0.1 -0.1;0.1 0.1;-0.1 0.1]';
% % fill(W(1,:),W(2,:),'r')
% % W1=AK*W;%s=1
% % hold on
% % fill(W1(1,:),W1(2,:),'b')
% % W2=AK*W1;%s=2
% % fill(W2(1,:),W1(2,:),'y')
% % s=2;a=0.4;%�ҵ�F(s,a)
Z=(W+AK*W+AK*AK*W);%���伯

% ������ǿԼ��
X_nor = X - Z;
U_nor = U - K*Z;
model = LTISystem('A',A,'B',B);
model.x.min = [-inf;-inf];
model.x.max = [inf;X_nor.b(2)];
model.u.min = -U_nor.b(3,1);
model.u.max = U_nor.b(4,1);
model.x.penalty = QuadFunction(Q);
model.u.penalty = QuadFunction(R);
model.x.with('terminalSet');
S1 = model.LQRSet();%��Լ�����ն˼�
model.x.terminalSet = S1;
model.x.with('terminalPenalty');
P1 = model.LQRPenalty();%%%��Ӧ�ͷ�Ȩ��
model.x.terminalPenalty = P1; 
mpc = MPCController(model,N);

RS = X_nor;
for i =1:N
    RS1{i,1} = model.reachableSet('X',X_nor,'U',U_nor,'N',i,'direction','backward');
    RS = RS1{i,1}&RS;
end
[RS2,RSN2] = model.reachableSet('X',S1,'U',U_nor,'N',N,'direction','backward');
RS = RS&RS2;
RS_Z = RS+Z;
figure
RS_Z.plot('Colormap','white');
hold on;
RS.plot()
axis([-20 50 -9 2])

x0 = [-5;-2];
x_obj = zeros(2,N+1);%�Ŷ�ϵͳ״̬
u_obj = zeros(1,N+1);%�Ŷ�ϵͳ����
x_star = zeros(2,N+1);%���壨�ο���ϵͳ״̬
u_star = zeros(1,N+1);%���壨�ο���ϵͳ����
x_obj(:,1) = x0; 
M = 9;
for i = 1:M+1
%     chuzhi = RS&(my+Z);
    chuzhi = Z.invAffineMap(-1,x_obj(:,i));
    [x_star(:,i),fval,flag] = fmincon(@(xx)xx'*P1.H*xx,[0;0],chuzhi.A,chuzhi.b,[],[],model.x.min,model.x.max);%�����壨�ο���ϵͳ�ĳ�ֵ
    if i == M+1
        break;
    end
    [u_star(:,i),feasible,openloop] = mpc.evaluate(x_star(:,i));
    u_obj(:,i) = u_star(:,i) + K*(x_obj(:,i) - x_star(:,i));
    x_obj(:,i+1) = A*x_obj(:,i) + B*u_obj(:,i) +unifrnd(-0.1,0.1,2,1);
end
t = 1:M+1;
S2 = S1+Z;
figure
S2.plot('ColorMap','white');
hold on
S1.plot();
for i = 1:M+1
    plot(x_star(:,i)+Z,'Colormap','cool');
end
plot(x_obj(1,:),x_obj(2,:),'-.y',x_star(1,:),x_star(2,:),'-b');
grid on;
axis([-8 4 -3 3])


