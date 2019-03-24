%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                           ����ϵͳ ���趨�㣨Ŀ���趨����Tubes����������֤
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

close all
clear
clc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                              RMPC_2006���Ĳ�������
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
N = 13;      %Ԥ����״̬����Ƴ���Լ������������Ԥ���򲽳���
STEP=50;     %���沽�������Ʋ�����
ITER=1;    %ƽ������
A=[1 1;0 1];
B=[1 1]';
b = [0;0]; 
z = [0;0];%�趨��
C=[1 1];
Q=eye(2);
R=0.01;
X = Polyhedron('lb',[-50;-50],'ub',[3;3]);
U = Polyhedron('lb',-3,'ub',3);
W = Polyhedron('lb',[-0.1;-0.1],'ub',[0.1;0.1]);
V = Polyhedron('lb',-0.05,'ub',0.05);
K = -[1 1];%��������
L = [1 1]';%�۲�������
x0 = [-3;-8];%�Զ���  ��ʼ״̬����ֵ

AL = A-L*C;%�۲�������
deta_ob = W+(-L*V);
[S_ob,flag1] = invariant_error(AL,deta_ob);%%�۲����伯
AK = A+B*K;%����������
deta_ctl = L*C*S_ob+L*V;
[S_ctl,flag2] = invariant_error(AK,deta_ctl);%%�۲����伯
S = S_ob+S_ctl;

% ������ǿԼ��
X_nor = X - S;
X_nor.minHRep();%��Լ��
U_nor = U - K*S_ctl;
U_nor.minHRep();%��Լ��
model = LTISystem('A',A,'B',B,'f',b);
model.x.penalty = QuadFunction(Q);
model.u.penalty = QuadFunction(R);
model.x.min = [-X_nor.b(1);-X_nor.b(2)];
model.x.max = [X_nor.b(3);X_nor.b(4)];
if(size(B,2) == 2)
    model.u.min = [-U_nor.b(1,1);-U_nor.b(2,1)];
    model.u.max = [U_nor.b(3,1);U_nor.b(4,1)];
else
    model.u.min = -U_nor.b(1,1);
    model.u.max = U_nor.b(2,1);
end
[S1,P1] = TerminalSet_and_Penalty(model,z);
model.x.with('terminalSet');
model.x.terminalSet = S1;
model.x.with('terminalPenalty');
model.x.terminalPenalty = QuadFunction(P1);
model.x.with('reference');
model.x.reference = z;
mpc = MPCController(model,N);

[RS2,RSN2] = model.reachableSet('X',S1,'U',U_nor,'N',N,'direction','backward');

RS = X_nor&RS2;
RS_Z1 = RS+S_ctl;
RS_Z = RS+S;
figure(1)
RS_Z.plot('Colormap','white');
hold on;
RS_Z1.plot('Colormap','gray');
RS.plot()
% axis([-55 10 -15 5])
RS_Z1.minHRep();

aver_x_x=zeros(2,STEP+1);
aver_x_ob=zeros(2,STEP+1);
aver_x_star=zeros(2,STEP+1);

mse_x_x=zeros(2,STEP+1);
mse_x_ob=zeros(2,STEP+1);
mse_x_star=zeros(2,STEP+1);

for iter=1:ITER
    x_ob = zeros(size(A,2),STEP+1);%�۲�״̬������ֵ��
    x_x = zeros(size(A,2),STEP+1);%�Ŷ�ϵͳ״̬
    y_y = zeros(size(C,1),STEP+1);%�Ŷ�ϵͳ״̬�۲�ֵ
    u_ob = zeros(size(B,2),STEP);%�Ŷ�ϵͳ����
    x_star = zeros(size(A,2),STEP+1);%���壨�ο���ϵͳ״̬
    u_star = zeros(size(B,2),STEP);%���壨�ο���ϵͳ����
    x_ob(:,1) = x0; 
    x_range = x_ob(:,1)+S_ob;
    x_range.minHRep();%��Լ��
    x_x(:,1) = x_range.interiorPoint().x;%the interior of x-range;
    y_y(:,1) = C*x_x(:,1)+unifrnd(-V.b(1),V.b(2));    

    for i = 1:STEP
        chuzhi = S_ctl.invAffineMap(-1,x_ob(:,i));
        [x_star(1:2,i),fval,flag] = fmincon(@(xx)(xx-z)'*P1*(xx-z),[0;0],chuzhi.A,chuzhi.b,chuzhi.Ae,chuzhi.be,model.x.min,model.x.max);%�����壨�ο���ϵͳ�ĳ�ֵ
        if i == STEP+1
            break;
        end
        
        [u_star(:,i),feasible,openloop] = mpc.evaluate(x_star(:,i));%nominal control
        x_star(:,i+1) = A*x_star(:,i)+B*u_star(:,i)+b;%nominal system
        u_ob(:,i) = u_star(:,i) + K*(x_ob(:,i) - x_star(:,i));%system
        x_ob(:,i+1) = A*x_ob(:,i) + B*u_ob(:,i) + b + L*(y_y(:,i)-C*x_ob(:,i));
        x_x(:,i+1) = A*x_x(:,i) + B*u_ob(:,i) + b + [normrnd(0,W.b(3)/3);normrnd(0,W.b(4)/3)];
        y_y(:,i+1) = C*x_x(:,i+1)+normrnd(0,V.b(2)/3);
    end
    aver_x_x_temp([2*(iter-1)+1,2*(iter-1)+2],:)=x_x;
    aver_x_ob_temp([2*(iter-1)+1,2*(iter-1)+2],:)=x_ob;
    aver_x_star_temp([2*(iter-1)+1,2*(iter-1)+2],:)=x_star;   
    
    mse_x_x_temp([2*(iter-1)+1,2*(iter-1)+2],:)=(x_x-repmat(z,1,STEP+1)).^2;%��ʵֵ��Ŀ������ƫ�
    mse_x_ob_temp([2*(iter-1)+1,2*(iter-1)+2],:)=(x_ob-repmat(z,1,STEP+1)).^2;
    mse_x_star_temp([2*(iter-1)+1,2*(iter-1)+2],:)=(x_star-repmat(z,1,STEP+1)).^2;  

end
aver_x_x(1,:)=sum(aver_x_x_temp(1:2:(2*ITER-1),:),1)/ITER;
aver_x_x(2,:)=sum(aver_x_x_temp(2:2:(2*ITER),:),1)/ITER;
aver_x_ob(1,:)=sum(aver_x_ob_temp(1:2:(2*ITER-1),:),1)/ITER;
aver_x_ob(2,:)=sum(aver_x_ob_temp(2:2:(2*ITER),:),1)/ITER;
aver_x_star(1,:)=sum(aver_x_star_temp(1:2:(2*ITER-1),:),1)/ITER;
aver_x_star(2,:)=sum(aver_x_star_temp(2:2:(2*ITER),:),1)/ITER;

mse_x_x(1,:)=sqrt(sum(mse_x_x_temp(1:2:(2*ITER-1),:),1)/ITER);
mse_x_x(2,:)=sqrt(sum(mse_x_x_temp(2:2:(2*ITER),:),1)/ITER);
mse_x_ob(1,:)=sqrt(sum(mse_x_ob_temp(1:2:(2*ITER-1),:),1)/ITER);
mse_x_ob(2,:)=sqrt(sum(mse_x_ob_temp(2:2:(2*ITER),:),1)/ITER);
mse_x_star(1,:)=sqrt(sum(mse_x_star_temp(1:2:(2*ITER-1),:),1)/ITER);
mse_x_star(2,:)=sqrt(sum(mse_x_star_temp(2:2:(2*ITER),:),1)/ITER);

S2 = S1+S_ctl;
S3 = S1+S;
figure(2);
S3.plot('ColorMap','gray');
hold on
S2.plot('ColorMap','lightgray');
S1.plot('ColorMap','summer');
for i = 1:STEP
    plot(aver_x_star(1:2,i)+S,'Colormap','cool',aver_x_star(1:2,i)+S_ctl,'Colormap','spring',...
        aver_x_ob(1:2,i)+S_ob,'Colormap','white');
end
plot(aver_x_x(1,:),aver_x_x(2,:),'--k',aver_x_ob(1,:),aver_x_ob(2,:),'-.r',aver_x_star(1,:),aver_x_star(2,:),'-b');
grid on;

% axis([-15 5 -10 5])








