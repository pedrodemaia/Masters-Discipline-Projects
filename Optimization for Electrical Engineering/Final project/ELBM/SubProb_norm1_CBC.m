function [x,flag]  = SubProb_norm1_CBC(CPM,xc,flev,pars,cpu)
%
if nargin<5
    cpu=inf;
else
    cpu = max(cpu,5);    
end
[nf,n] = size(CPM.Gf);
nc     = length(CPM.bc);
%--------------------------------------------------------------------------
% Model for f
A      = [CPM.Gf zeros(nf,n)]; 
b      = CPM.bf + flev;
%--------------------------------------------------------------------------
% Model for c, if any
if isempty(CPM.bc)==0
     A = [A; CPM.Gc zeros(nc,n)];
     b = [b;CPM.bc];
end
%--------------------------------------------------------------------------
% Append constraint Ax <= b, if any
if isempty(pars.X.A)==0
    A = sparse([A; pars.X.A zeros(size(pars.X.A,1),n)]);
    b = [b;pars.X.b];
end
%--------------------------------------------------------------------------
% Append constraint related to the norm 1
A = sparse([A;eye(n), -eye(n);-eye(n),-eye(n)]);
b = [b;xc;-xc];
%
%--------------------------------------------------------------------------
Aeq =[];beq=[];
if isempty(pars.X.Aeq)==0
   Aeq = sparse([pars.X.Aeq,zeros(size(pars.X.Aeq,1),n)]);
   beq = pars.X.beq;
end
%==========================================================================
f   = [zeros(n,1);ones(n,1)];
lb = [pars.X.lb;zeros(n,1)];
ub = [pars.X.ub;inf(n,1)];
vtype=pars.vtype;
for i=1:n;vtype=strcat(vtype,'c');end
%
[x,exitflag]=call_cbc(f,A,b,Aeq,beq,lb,ub,vtype,cpu,pars.MIPGap,pars.MIPMaxSol);
 if (exitflag>=0)
    x = x(1:n);
    flag =1;
else
    flag =-1;
    x =xc;
 end
return
