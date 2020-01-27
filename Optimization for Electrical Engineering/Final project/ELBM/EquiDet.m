function out = EquiDet(pars)
%
% Esta rotina monta o Equivalente determinístico e resolve
t0 =tic;
%==========================================================================
Ncen  = pars.Ncen;
P     = ones(Ncen,1)/Ncen;
seed = pars.seed;
%========================================================================== 

%[~,~,W,~,A,C,b]= feval(pars.problem,1,0,pars.scena);
[hm,qm,W,T,A,C,b,sigmah]= feval(pars.problem);
%==========================================================================
[na1,ma1] = size(A);
[na2,ma2] = size(W);
nd        = na2;
md        = ma1;
ncol      = ma1 + Ncen*ma2;
A         = [A, zeros(na1,ncol - ma1)];
%==========================================================================
vtype = pars.vtype;
v     =[];
for i=1:ma2;
    v = [v,'c'];
end
randn('state',seed);
rand('state',seed);
n2 = length(qm);
m2 = length(hm);
A  = sparse(A);
for icen = 1:Ncen
 %       [h,q,W,T]= feval(pars.problem,icen,2,pars.scena);
        h     = hm + randn(m2,1).*sigmah;
        q     = rand(n2,1).*qm*2;
        mcol  = ma2*(icen-1);
        Zero1 = zeros(nd,mcol);
        mcol  = ncol - ( md + icen*ma2);
        Zero2 = zeros(nd,mcol);
        aux   = sparse([T,Zero1,W,Zero2]);
        A     = [A; aux];
        b     = [b;h];
        C     = [C;P(icen)*q];
        vtype = [vtype,v];
end

%==========================================================================
% Resolve o PL-único
lb=zeros(ncol,1);
ub=inf(ncol,1);
ub(1:ma1)=pars.X.ub;
out.n                    = ncol;
out.m                    = length(b);
[out.sol,e,info,out.fopt]=call_cbc(C,[],[],A,b,lb,ub,vtype,pars.cpu,pars.tol,inf,1);
out.ncall                 = NaN;
out.cpu                   = toc(t0);
out.Nodes                 = info.Nodes;

return
