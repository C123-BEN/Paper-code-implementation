Clock%20synchronization/% Kalman Filtering With Intermittent Observations(2004)
close all
clear
clc
A=[1.25 1 0;0 0.9 7;0 0 0.6];C=[1 0 2];Q=20*eye(3,3);R=2.5;       % ��������
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
lambdadown=1-1/(max(eig(A)))^2;   %�½�
lambda=0:0.002:1;                 %���ò��������ƺþ��ȣ��漰�Ͻ�ľ��ȣ���̫��Ӱ�쾫�ȣ�̫СӰ��Ч�ʣ�
Trs=1e5*ones(size(lambda));   %��������
k=1;
for i=lambda
    A1=A*sqrt(1-i);
    if i>lambdadown
       s=dlyap(A1,Q);
       Trs(k)=trace(s);
    end
    k=k+1;
end
plot(lambda,Trs,'-.r')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%           
n=length(lambda);     %�Ͻ�
T=zeros(n,1);
for i=1:n
    setlmis([]);
    Y=lmivar(1,[3,1]);       %�����Aͬ�׵ĶԳƾ���
    Z=lmivar(2,[3,1]);       %����Z�����������A������ȣ��������C���������
    lmiterm([-1 1 1 Y],1,1);
    lmiterm([-1 1 2 Y],sqrt(lambda(i)),A);
    lmiterm([-1 1 2 Z],1,C);
    lmiterm([-1 1 3 Y],sqrt(1-lambda(i)),A);
    lmiterm([-1 2 2 Y],1,1);
    lmiterm([-1 3 3 Y],1,1);
    lmiterm([-2 1 1 Y],1,1);
    lmiterm([-3 1 1 0],1);
    lmiterm([3,1 1,Y],1,1);
    lmisys=getlmis;
    options=[0 0 0 0 1];
    [t,xopt]=feasp(lmisys,options);
    T(i)=t;
end
for j=1:n
    if T(j)<=0
        lambdaup=lambda(j);
        break
    end
end
TrV=zeros(size(lambda));
k1=1;
for i=lambda
    m=100;                         %����������йأ����������㹻��
    v=ones([size(A),m]);       %���ʼֵ�йأ�Ϊʹ�������������ʼֵ���
    for j=1:m
        v(:,:,j+1)=A*v(:,:,j)*A'+Q-i*A*v(:,:,j)*C'*inv(C*v(:,:,j)*C'+R)*C*v(:,:,j)*A';
    end
    TrV(k1)=trace(v(:,:,m+1));
    k1=k1+1;
end
hold on
plot(lambda,TrV,'-b')
legend('S','V')
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
h=5e6;                                    %�߶ȷ�Χ
n=0:h;
lambdadown=lambdadown*ones(size(n));
lambdaup=lambdaup*ones(size(n));
hold on
plot(lambdadown,n,'--g',lambdaup,n,'--k')
%text(0.3,5,['\lambda','c=',num2str(lambdadown)])
xlabel('\lambda')
ylabel('S/V')
title('Special case:C is invertible')
text(0.35,-300000,'$\underline{\lambda}$','interpreter','latex');
text(0.33,300000,'$\overline{\lambda}$','interpreter','latex');
axis([0,1,0,h]);                               %%ע�����Χ
