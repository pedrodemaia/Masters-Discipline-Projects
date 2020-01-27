function out = RUN(Method)
%--------------------------------------------------------------------------
% Welington de Oliveira
%
% Subroutine for solving two-stage stochastic linear programming problems
% with mixed-binary first-stage variables.
% The three considered problems are the ones presented in:
% Regularized optimization methods for convex MINLP problems, 
% available at www.oliveira.mat.br
%--------------------------------------------------------------------------
% This package requires OPTI Toolbox for Matlab:
% http://www.i2c2.aut.ac.nz/Wiki/OPTI/index.php/Main/HomePage
%--------------------------------------------------------------------------
global Nodes
%
% Available solvers
solver ={'ECPM','ELBM-1','ELBM-I','MILP'};
% Method=[ 1        2        3       4]
% ECPM   -> Extended cutting-plane method
% ELBM   -> Extended level bundle method with norm-1 regularization
% ELBM   -> Extended level bundle method with norm-inf regularization
% MILP   -> Formulates the problem as a large MILP problem and solves via CBC
%
%Method = 1;
%--------------------------------------------------------------------------
% Parameters
tol       = 1e-5;
MaxIt     = 10000;
cpu       = 2*(3600);
MIPGap    = 0.05;  % 20%
MIPMaxSol = 1;
N   = 10;
pbm = {'expTerm'};             % Problem's name
%--------------------------------------------------------------------------
% Save results in files 
for i=1:length(Method)
     m = Method(i);
     fid(i) = fopen(strcat(char(solver(m)),'.txt'),'w');
     fprintf(fid(i),'%15s, %5s, %5s,  %15s, %10s, %10s, %10s, %10s, %5s, %5s \n',...
                'Problem', 'n','m', 'fopt','copt','cpu-bb','cpu-Sub','cpu','ncall','Nodes');
end
%--------------------------------------------------------------------------
% Get the problems 
np  = length(pbm);
nn  = length(N);
for p=1:np
    for icen=1:nn
        for iseed =1:1                     % change here for more instances
        problem = char(pbm(p));
        pars   = getdata(problem);
        pars.seed=iseed;
        pars.Ncen=N;
        pars.MaxIt  = MaxIt;
        pars.MaxBun = MaxIt;
        pars.tol    = tol;
        pars.ml     = 0.2;
        pars.Center = 1;   % Change here to 0 (zero) if you wish current stability center
        pars.Stab   = 1;
        pars.fid    = fopen('output.txt','w');
        pars.cpu    = cpu;
        pars.MIPGap = MIPGap;
        pars.MIPMaxSol=MIPMaxSol;      
        
        for i=1:length(Method)
           Nodes   = 0;
            m = Method(i);
            if m<=3
                if m==1
                    pars.Stab = 0;
                elseif m==2
                    pars.Stab = 1;
                elseif m==3
                    pars.Stab = inf;
                end
                out = ELBM(pars.x0,pars);
            else
                out = EquiDet(pars);
                Nodes = out.Nodes;
                out.copt =0;
                out.cpubb=0;out.cpuSub=0;
            end
            fprintf(fid(i),'%15s, %5.0f, %5.0f,  %15.3f, %10.5f, %10.2f, %10.2f, %10.2f, %5.0f, %5.0f \n',...
                char(pbm(p)), iseed,pars.Ncen, out.fopt,out.copt,out.cpubb,out.cpuSub,out.cpu,out.ncall,Nodes);
        end
        end
   end
end
fclose all    
return
