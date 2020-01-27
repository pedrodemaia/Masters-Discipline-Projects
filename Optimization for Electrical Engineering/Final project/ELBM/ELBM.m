function out = ELBM(x,pars)
%
%  Extended Level Bundle Methods, by Welington de Oliveira 
%                www.oliveira.mat.br
%
%==========================================================================
oracle   = pars.bb;       % Oracle or black-box
MaxIt    = pars.MaxIt;    % Maximum number of iteration
Tol      = pars.tol;      % Tolerance for the stopping test
flow     = pars.flow;     % Lower bound for the optimal value (can be -inf)
ml       = pars.ml;       % Parameter for the level (0,1)
ic       = pars.Center;   % Parameter for the stability center {0,1}
stabfun  = pars.Stab;     % Stability function
fid      = pars.fid;      % To print results
constant=1;
fup = inf;
%--------------------------------------------------------------------------
tstart = tic;        % initialize time counter 
%==========================================================================
xc              = x(:);           % initial point
pars.x          = xc;
cpubb           = tic;
[fx,gfx,cx,gcx] = feval(oracle,pars);% oracle call
out.cpubb       = toc(cpubb);
CPM.Gf = gfx'; CPM.bf = gfx'*pars.x - fx;
if(~isempty(cx)),CPM.Gc = gcx'; CPM.bc = gcx'*pars.x - cx;
else CPM.Gc=[];CPM.bc=[]; end
%==========================================================================
% Inicialize bundle information
F  = fx;  C  = max(cx); X=x;       % save the function values
%==========================================================================
% More inicialization...
k       = 0;                % Iteration counter 
ncall   = 1;                % Oracal call 
nempty  = 0;                % empty level set counter
hkl     = inf;              % cycle
msg     = 'Maximum number of iterations';  
%escreveinfo(fid);    % write current information
%==========================================================================
% Loop
while ( k < MaxIt )
    k    = k + 1;  
    %======================================================================
    % Step 1: Stopping test
    %----------- Improvemet function --------------------------------------
    nbun = length(F);
    if isempty(C)==1
        aux = F-ones(nbun,1)*flow;
    else
        aux = max(F-ones(nbun,1)*flow,constant*C);
    end
    [hk,ibest] = min(aux);
    if isempty(C)==1, cbest=0;else cbest=C(ibest);end
    %----------------------------------------------------------------------
    nbun = nbun +length(CPM.bc);
    cmax = max(cx);
    escreveinfo(fid,k,nbun,fx,cmax,hk,toc(tstart),ncall,flow);
    escreveinfo(1,k,nbun,fx,cmax,hk,toc(tstart),ncall,flow);
    %----------- Stopping test --------------------------------------------
    if ((F(ibest)-flow) <= (1+abs(flow))*Tol) && (cbest <= Tol)
         msg='Optimality';
        break;
    elseif (toc(tstart)>pars.cpu), msg='CPU time exceeded';
        break;        
    end  
    %======================================================================
    % Step 2: Cycle update    
    if (hk <= (1-ml)*hkl)
        hkl = hk;
        xc = X(:,ibest);
    end
    %======================================================================
    % Step 3: Level update
    flev = flow + ml*hk;
    xc   = (1-ic)*x + ic*xc;
    %======================================================================
    % Step 4: New iterate
    if (stabfun == 1)
        [x,flag]  = SubProb_norm1_CBC(CPM,xc,flev,pars,pars.cpu-toc(tstart));
    elseif (stabfun == inf)
        [x,flag]  = SubProb_norminf_CBC(CPM,xc,flev,pars,pars.cpu-toc(tstart));
    else
        [flow,x]  = SubProb_CP_CBC(CPM,flow,pars,pars.cpu-toc(tstart));flag=1;
    end
    if flag<1 % Level set infeasible
       fprintf(1,' ----------- Updating lower bound -----------\n'); 
        nempty = nempty + 1;
        flow   = flev;
        continue
    end
    %======================================================================
    % Step 5: Oracle call
    pars.x = x; 
    cpubb  = tic;
    [fx,gfx,cx,gcx] = feval(oracle,pars);
    out.cpubb       = out.cpubb+toc(cpubb);
    ncall = ncall+1;
    %
    CPM.Gf = [CPM.Gf;gfx']; CPM.bf =[CPM.bf; gfx'*pars.x - fx];
    if(~isempty(cx)),CPM.Gc = [CPM.Gc;gcx']; CPM.bc =[CPM.bc; gcx'*pars.x - cx];end
    X=[X,x];
    %======================================================================
    % Step 6: Bundle Update
    F = [F;fx]; C = [C;max(cx)]; 
end
%--------------------------------------------------------------------------
fopt = F(ibest); 
sol  = X(:,ibest);
if isempty(C)==0
    copt = C(ibest); 
else
    copt = 0;
end
fprintf(1,'%s \n',msg);

out.sol=sol;
out.fopt = fopt;
out.copt = copt;
out.k=k;
out.nempty=nempty;
out.ncall=ncall;
out.cpu = toc(tstart);
out.cpuSub = out.cpu - out.cpubb;
return