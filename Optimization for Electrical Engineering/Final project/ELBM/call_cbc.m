function [x,exitflag,info,fval]=call_cbc(f,A,b,Aeq,beq,lb,ub,xtype,cpu,MIPGap,MaxSol,displ)
global Nodes
nineq = length(b);
neq = length(beq);
if neq>0
    A = [A;Aeq];
    rl=[-inf(nineq,1);beq];
    ru=[b;beq];
else
    rl=-inf(nineq,1);
    ru=b;
end
if nargin<12
    displ=0;
end
%--------------------------------------------------------------------
%options
popts = cbcset;
%Add in options from optiset   
popts.maxtime = cpu;
if ~isempty(MIPGap)
    popts.allowableFracGap=MIPGap;
end
if ~isempty(MaxSol)
    popts.maxSolutions=MaxSol;
end
popts.display=displ;
%popts.primalTol = 1e-5;
%popts.dualTol = 1e-5;
%popts.intTol = 1e-5;

%MEX contains error checking
[x,fval,status,iter,cobj] = cbc([], f, A, rl, ru, lb, ub, xtype, [], [],popts);

%Assign Outputs
info.Nodes = iter;
info.AbsGap = abs(cobj-fval);
info.RelGap = abs(cobj-fval)/(1e-1 + abs(fval));
Nodes = Nodes + iter;
if status~=0
    fval = cobj; % lower bound
end
switch(status)
    case 0
        info.Status = 'Integer Optimal';
        exitflag = 1;
    case 1
        info.Status = 'Linear Relaxation Infeasible';
        exitflag = -1;
    case 2
        info.Status = 'Gap Reached';
        exitflag = 1;
    case 3        
        info.Status = 'Maximum Nodes Reached';
        exitflag = 0;
    case 4
        info.Status = 'Maximum Time Reached';
        exitflag = 0;
%         if (abs(cpu-15)<=1e-5) && (info.RelGap>.5)
%             disp('Marretada *** call_cbc');
%             x=[];
%         end
    case 5
        info.Status = 'User Exited';
        exitflag = -5;
    case 6
        info.Status = 'Number of Solutions Reached';
        exitflag = 0;
    case 7
        info.Status = 'Linear Relaxation Unbounded';
        exitflag = -2;
	case 8
        info.Status = 'Proven Infeasible';
        exitflag = -1;
    otherwise
        info.Status = 'Unknown Termination';
        exitflag = -3;
end
return