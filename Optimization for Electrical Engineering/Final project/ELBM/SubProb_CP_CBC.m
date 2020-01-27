function [flow,x,exitflag]  = SubProb_CP_CBC(CPM,flow,pars,cpu,MIPGap)
%
% This routine solves the problem:
%    min \check{f}(x)
%      subject to Aeq*x = beq, 
%                 Ax   <= b, 
%                 \check{c} <= 0
%                 0 <= x <= ub,
%                 x \in Z^n1 x R^n2
%
% Get the information on the feasible set from the Matlab routine feaset,
% provided by the user.
%
%
if nargin<4
    cpu=inf;
else
    cpu = max(cpu,5);
end
if nargin<5
    MIPGap = [];
end
[nk,n] = size(CPM.Gf);
nc     = length(CPM.bc);
%--------------------------------------------------------------------------
% Model for f
A      = [CPM.Gf -ones(nk,1)]; 
b      = CPM.bf;
%--------------------------------------------------------------------------
% Model for c, if any
if isempty(CPM.bc)==0
     A = [A; CPM.Gc zeros(nc,1)];
     b = [b;CPM.bc];
end
%--------------------------------------------------------------------------
% Append constraint Dx <= dd, if any
if isempty(pars.X.A)==0
    A = [A; pars.X.A zeros(size(pars.X.A,1),1)];
    b = [b;pars.X.b];
end
%==========================================================================
Aeq =[];beq=[];
if isempty(pars.X.Aeq)==0
   Aeq   = [pars.X.Aeq,zeros(size(pars.X.Aeq,1),1)];
   beq   = pars.X.beq;
end
f   = [zeros(n,1);1];
lb = [pars.X.lb;flow];
ub = [pars.X.ub;inf];
vtype=[pars.vtype,'c'];

[x,exitflag,~,fval]=call_cbc(f,sparse(A),b,sparse(Aeq),beq,lb,ub,vtype,cpu,MIPGap,[]);
%
%if (exitflag>0)
    flow = max(fval,flow);
   try x    = x(1:n);end
    flag =1;
%else
%    flag=-1;
%    x = [];
%    error('The problem is infeasible');
%end
return
