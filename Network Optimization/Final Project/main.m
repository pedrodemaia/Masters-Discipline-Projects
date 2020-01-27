clear all
close all
clc

load dados.mat

% seleção de quantas usinas da cascata e períodos considerar
numUsinas = 12;
numPeriodos = 12;

% parâmetros do problema
volumeInicial = 0.5; % volume inicial (50% do reservatório)
volumeFinal = 0.75; % volume final (75% do reservatório) 

a = a(1:numUsinas,1:numPeriodos);
P = P(1:numUsinas);
M = M(1:numUsinas);
Q = Q(1:numUsinas,:);
rho = rho(1:numUsinas);
S = S(1:numUsinas);
usinas = usinas(1:numUsinas);
V = V(1:numUsinas,:);

U = length(usinas); % número de usinas
T = size(a,2); % número de períodos

% parâmetros não disponíveis
D = 1.5e10*ones(T,1); % demanda de cada período
cu = ones(U,1); % custo de produção de cada hidrelétrica
ca = 10; % custo de produção por fontes alternativas
V0 = V(:,1) + volumeInicial*(V(:,2)-V(:,1)); % volume inicial

% engolimentos mínimo e máximo
E = zeros(U,2);
for i =1:length(P)
E(i,1) = min(P{i}(:,1));
E(i,2) = sum(P{i}(:,2));
end

% manutenções
usinasComManutencao = [];
cumMan = [];
nm = 0;
for i=1:numUsinas
    if any(M{i})
        usinasComManutencao = [usinasComManutencao i];
        cumMan = [cumMan nm];
        nm = nm + M{i}(3) - M{i}(2) + 1;
    end
end


% índice inicial e final das variáveis de cada tipo
% as variáveis estão agrupadas inicialmente por usina e depois por período
% de forma que todas as variáveis de um mesmo período são adjacentes
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
mi = ff + 1;
mf = mi + nm - 1;

% número de variáveis do modelo
xn = 4 * U*T + T + nm;

% funcao objetivo
% min custo
c = [zeros(1, gi-1) repmat(cu', 1, T) ca*ones(1, T) zeros(1,nm)];

% limites das variáveis
xmin = [repmat(V(:,1),T,1); repmat(E(:,1),T,1); zeros(2*U*T+T+nm,1)];
xmax = [repmat(V(:,2),T,1); repmat(E(:,2),T,1); ...
    repmat(S,T,1); repmat(D,U+1,1); ones(nm,1)];

% volume mínimo ao final da otimização
xmin(vf-U+1:vf) =  V(:,1) + volumeFinal*(V(:,2)-V(:,1));

% restrição de atendimento de demanda
Aeqdem = zeros(T,xn);
for t=1:T
   Aeqdem(t,gi+U*(t-1):gi+U*t-1) = 1;
end
Aeqdem(:,fi:ff) = eye(T);
beqdem = D(:);

% restrição de geração de energia
Aeqgen = zeros(U*T,xn);
Aeqgen(:,gi:gf) = eye(U*T);
Aeqgen(:,qi:qf) = diag(reshape(repmat(-rho',1,U),U*T,1));
beqgen = zeros(U*T,1);

% restrição de balanço hídrico
Aeqbh = zeros(U*T,xn);
Aeqbh(:,vi:vf) = eye(U*T); % volume do período atual
Aeqbh(:,qi:qf) = eye(U*T); % turbinado pela usina
Aeqbh(:,si:sf) = eye(U*T); % vertido pela usina
for u=1:U
    for t=1:T-1
        Aeqbh(u+U*t,vi-1+u+U*(t-1)) = -1; % volume do período anterior
    end
end
for u=2:U
    for t=1:T
        Aeqbh(u+U*(t-1),qi-1+u-1+U*(t-1)) = -1; % turbinado pela montante
        Aeqbh(u+U*(t-1),si-1+u-1+U*(t-1)) = -1; % vertido pela montante
    end
end
beqbh = a(:) + [V0(:); zeros(U*(T-1),1)];

% restrição de limite de defluência
Amindeflu = zeros(U*T,xn);
Amindeflu(:,qi:qf) = -1*eye(U*T);
Amindeflu(:,si:sf) = -1*eye(U*T);
bmindeflu = repmat(-Q(:,1),T,1);

Amaxdeflu = zeros(U*T,xn);
Amaxdeflu(:,qi:qf) = eye(U*T);
Amaxdeflu(:,si:sf) = eye(U*T);
bmaxdeflu = repmat(Q(:,2),T,1);

% restrição de engolimento máximo com manutenção
Amaxeng = zeros(U*T,xn);
Amaxeng(:,qi:qf) = eye(U*T);
cont = 0;
for u=usinasComManutencao
    temp = M{u};
    eng = temp(4)*E(u,2);
    for t=temp(2):temp(3)
        duracao = temp(1)-1;
        conti = 0;
        while duracao > 0
            Amaxeng(u+U*(t-1+conti),mi+cont) = (mod(duracao,30)+1)*eng/30;
            duracao = duracao - 30;
            conti = conti + 1;
        end
        cont = cont + 1;
    end
end
bmaxeng = repmat(E(:,2),T,1);

% restrição de unicidade de manutenções
Aeqman = zeros(numel(usinasComManutencao),xn);
for i=1:numel(usinasComManutencao)-1
    Aeqman(i, mi+cumMan(i):mi+cumMan(i+1)-1) = 1;
end
Aeqman(end, mi+cumMan(end):end) = 1;
beqman = ones(numel(usinasComManutencao),1);

% agregação das restrições
A = [Amindeflu; Amaxdeflu; Amaxeng];
b = [bmindeflu; bmaxdeflu; bmaxeng];

Aeq = [Aeqdem; Aeqgen; Aeqbh; Aeqman];
beq = [beqdem; beqgen; beqbh; beqman];

% construção do modelo
model.obj = c;
model.modelsense = 'min';
model.A = sparse([A; Aeq]);
model.rhs = [b; beq];
model.sense = [repmat('<',1,length(b)) repmat('=',1,length(beq))];
model.vtype = [repmat('C',1,xn-nm) repmat('I',1,nm)];
model.lb = xmin;
model.ub = xmax;

params.outputflag = 0;

%Resolve o problema
result = gurobi(model,params);

volumes = reshape(result.x(vi:vf),U,T);
engolimentos = reshape(result.x(qi:qf),U,T);
vertimentos = reshape(result.x(si:sf),U,T);
geracoes = reshape(result.x(gi:gf),U,T);
geracaoComp = result.x(fi:ff);

allManut = result.x(mi:mf);
cumMan = [cumMan nm];
manutencoes = [];
i = 0;
for u=usinasComManutencao
    i = i+1;
    temp = M{u};
    periods = temp(2):temp(3);
    manut = allManut(cumMan(i)+1:cumMan(i+1));
    id = find(manut > 0.99);
    manutencoes = [manutencoes; periods(id)];
end