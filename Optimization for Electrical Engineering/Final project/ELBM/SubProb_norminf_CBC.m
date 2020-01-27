function [x,flag]  = SubProb_norminf_CBC(CPM,xc,flev,pars,cpu)
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
A      = [CPM.Gf zeros(nf,1)]; 
b      = CPM.bf + flev;
%--------------------------------------------------------------------------
% Model for c, if any
if isempty(CPM.bc)==0
     A = [A; CPM.Gc zeros(nc,1)];
     b = [b;CPM.bc];
end
%--------------------------------------------------------------------------
% Append constraint Ax <= b, if any
if isempty(pars.X.A)==0
    A = [A; pars.X.A zeros(size(pars.X.A,1),1)];
    b = [b;pars.X.b];
end
%--------------------------------------------------------------------------
% Append constraint related to the norm 1
A = [A;eye(n), -ones(n,1);-eye(n),-ones(n,1)];
b = [b;xc;-xc];
%
%--------------------------------------------------------------------------
Aeq =[];beq=[];
if isempty(pars.X.Aeq)==0
   Aeq = [pars.X.Aeq,zeros(size(pars.X.Aeq,1),1)];
   beq = pars.X.beq;
end
%==========================================================================
f   = [zeros(n,1);1];
lb = [pars.X.lb;0];
ub = [pars.X.ub;inf];
vtype= [pars.vtype,'c'];
[x,exitflag]=call_cbc(f,sparse(A),b,sparse(Aeq),beq,lb,ub,vtype,cpu,pars.MIPGap,pars.MIPMaxSol);
if (exitflag>=0)
    x = x(1:n);
    flag =1;
else
    flag =-1;
    x =xc;
end
return
