clear all
close all
clc

load dados.mat

% sele��o de quantas usinas da cascata e per�odos considerar
numUsinas = 12;
numPeriodos = 12;

% par�metros do problema
volumeInicial = 0.5; % volume inicial (50% do reservat�rio)
tol = 0.0; % toler�ncia nos limites do problema
numPontos = 20; % n�mero de pontos do e-restrito

a = a(1:numUsinas,1:numPeriodos);
P = P(1:numUsinas);
Q = Q(1:numUsinas,:);
rho = rho(1:numUsinas);
S = S(1:numUsinas);
usinas = usinas(1:numUsinas);
V = V(1:numUsinas,:);

U = length(usinas); % n�mero de usinas
T = size(a,2); % n�mero de per�odos
xn = 4 * U*T + T;

% par�metros ainda n�o dispon�veis
D = 1e10*ones(T,1); % demanda de cada per�odo
cu = ones(U,1); % custo de produ��o de cada hidrel�trica
ca = 10; % custo de produ��o por fontes alternativas
V0 = V(:,1) + volumeInicial*(V(:,2)-V(:,1)); % volume inicial

% engolimentos m�nimo e m�ximo
E = zeros(U,2);
for i =1:length(P)
E(i,1) = min(P{i}(:,1));
E(i,2) = sum(P{i}(:,2));
end

% inclus�o de toler�ncia nos limites
V = [(1-tol)*V(:,1) (1+tol)*V(:,2)];
E = [(1-tol)*E(:,1) (1+tol)*E(:,2)];
Q = [(1-tol)*Q(:,1) (1+tol)*Q(:,2)];
S = (1+tol)*S;


% �ndice inicial e final das vari�veis de cada tipo
% as vari�veis est�o agrupadas inicialmente por usina e depois por per�odo
% de forma que todas as vari�veis de um mesmo per�odo s�o adjacentes
vi = 1;
vf = vi + U*T - 1;
qi = vf + 1;
qf = qi + U*T - 1;
si = qf + 1;
sf = si + U*T - 1;
gi = sf + 1;
gf = gi + U*T - 1;
fi = gf + 1;
ff = fi + T - 1;

% funcoes objetivo
% min custo
c1 = [zeros(1, gi-1) repmat(cu', 1, T) ca*ones(1, T)];
% max volume final
c2 = zeros(1,xn);
c2(vi+U*(T-1):vf) = -1;

% limites das vari�veis
xmin = [repmat(V(:,1),T,1); repmat(E(:,1),T,1); zeros(2*U*T+T,1)];
xmax = [repmat(V(:,2),T,1); repmat(E(:,2),T,1); repmat(S,T,1); repmat(D,U+1,1)];

% restri��o de atendimento de demanda
Aeqdem = zeros(T,xn);
for t=1:T
   Aeqdem(t,gi+U*(t-1):gi+U*t-1) = 1;
end
Aeqdem(:,fi:ff) = eye(T);
beqdem = D(:);

% restri��o de gera��o de energia
Aeqgen = zeros(U*T,xn);
Aeqgen(:,gi:gf) = eye(U*T);
Aeqgen(:,qi:qf) = diag(reshape(repmat(-rho',T,1),U*T,1));
beqgen = zeros(U*T,1);

% restri��o de balan�o h�drico
Aeqbh = zeros(U*T,xn);
Aeqbh(:,vi:vf) = eye(U*T); % volume do per�odo atual
Aeqbh(:,qi:qf) = eye(U*T); % turbinado pela usina
Aeqbh(:,si:sf) = eye(U*T); % vertido pela usina
for u=1:U
    for t=1:T-1
        Aeqbh(u+U*t,vi-1+u+U*(t-1)) = -1; % volume do per�odo anterior
    end
end
for u=2:U
    for t=1:T
        Aeqbh(u+U*(t-1),qi-1+u-1+U*(t-1)) = -1; % turbinado pela montante
        Aeqbh(u+U*(t-1),si-1+u-1+U*(t-1)) = -1; % vertido pela montante
    end
end
beqbh = a(:) + [V0(:); zeros(U*(T-1),1)];

% restri��o de limite de deflu�ncia
Amindeflu = zeros(U*T,xn);
Amindeflu(:,qi:qf) = -1*eye(U*T);
Amindeflu(:,si:sf) = -1*eye(U*T);
bmindeflu = repmat(-Q(:,1),T,1);

Amaxdeflu = zeros(U*T,xn);
Amaxdeflu(:,qi:qf) = eye(U*T);
Amaxdeflu(:,si:sf) = eye(U*T);
bmaxdeflu = repmat(Q(:,2),T,1);

% agrega��o das restri��es
A = [Amindeflu; Amaxdeflu];
b = [bmindeflu; bmaxdeflu];

Aeq = [Aeqdem; Aeqgen; Aeqbh];
beq = [beqdem; beqgen; beqbh];

model.obj = c1;
model.modelsense = 'min';
model.A = sparse([A; Aeq]);
model.rhs = [b; beq];
model.sense = [repmat('<',1,length(b)) repmat('=',1,length(beq))];
model.vtype = repmat('C',1,xn);
model.lb = xmin;
model.ub = xmax;

params.outputflag = 0;

C = zeros(2,2); % valor �timo para cada objetivo

%Resolve o problema para o 1o objetivo
result1 = gurobi(model,params);

C(1,1) = result1.objval;
C(2,1) = c2*result1.x;

%Resolve o problema para o 2o objetivo
model.obj = c2;
result2 = gurobi(model,params);

C(1,2) = c1*result2.x;
C(2,2) = result2.objval;

pontos1 = linspace(C(2,1),C(2,2),numPontos/2+2);
pontos1 = pontos1(2:end-1);

pontos2 = linspace(C(1,1),C(1,2),numPontos/2+2);
pontos2 = pontos2(2:end-1);

model.obj = c1;
model.A = sparse([A; Aeq; c2]);
model.sense = [model.sense '<'];

xe = [result1.x zeros(xn,numPontos) result2.x];
Ce = [C(:,1) zeros(2,numPontos) C(:,2)];

volumes = cell(numPontos+2,1);
engolimentos = cell(numPontos+2,1);
vertimentos = cell(numPontos+2,1);
geracoes = cell(numPontos+2,1);
geracaoComp = cell(numPontos+2,1);

volumes{1} = reshape(result1.x(vi:vf),U,T);
engolimentos{1} = reshape(result1.x(qi:qf),U,T);
vertimentos{1} = reshape(result1.x(si:sf),U,T);
geracoes{1} = reshape(result1.x(gi:gf),U,T);
geracaoComp{1} = result1.x(fi:ff);

volumes{end} = reshape(result2.x(vi:vf),U,T);
engolimentos{end} = reshape(result2.x(qi:qf),U,T);
vertimentos{end} = reshape(result2.x(si:sf),U,T);
geracoes{end} = reshape(result2.x(gi:gf),U,T);
geracaoComp{end} = result2.x(fi:ff);

for i=1:numPontos/2
    model.rhs = [b; beq; pontos1(i)];
    
    result = gurobi(model,params);
    xe(:,i+1) = result.x;
    
    Ce(1,i+1) = c1*result.x;
    Ce(2,i+1) = c2*result.x;
    
    if ~isempty(result.x)
        volumes{i+1} = reshape(result.x(vi:vf),U,T);
        engolimentos{i+1} = reshape(result.x(qi:qf),U,T);
        vertimentos{i+1} = reshape(result.x(si:sf),U,T);
        geracoes{i+1} = reshape(result.x(gi:gf),U,T);
        geracaoComp{i+1} = result.x(fi:ff);
    end
end

model.obj = c2;
model.A = sparse([A; Aeq; c1]);

for j=1:numPontos/2
    i = numPontos/2 + j;
    model.rhs = [b; beq; pontos2(j)];
    
    result = gurobi(model,params);
    xe(:,i+1) = result.x;
    
    Ce(1,i+1) = c1*result.x;
    Ce(2,i+1) = c2*result.x;
    
    if ~isempty(result.x)
        volumes{i+1} = reshape(result.x(vi:vf),U,T);
        engolimentos{i+1} = reshape(result.x(qi:qf),U,T);
        vertimentos{i+1} = reshape(result.x(si:sf),U,T);
        geracoes{i+1} = reshape(result.x(gi:gf),U,T);
        geracaoComp{i+1} = result.x(fi:ff);
    end
end

plot(Ce(1,1:numPontos/2),Ce(2,1:numPontos/2),'ob')
hold on
plot(Ce(1,numPontos/2+1:numPontos),Ce(2,numPontos/2+1:numPontos),'xr')

figure;
plot(Ce(1,:),Ce(2,:),'.')