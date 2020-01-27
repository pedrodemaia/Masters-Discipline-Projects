function pars= getdata(problem)
     
    pars.problem = problem;
   [~,~,~,~,pars.X.Aeq,c,pars.X.beq]= feval(problem);
   [pars.m,pars.n] = size(pars.X.Aeq);
   pars.X.A  = [];
   pars.X.lb = zeros(pars.n,1);
   pars.X.ub = 100*ones(pars.n,1);
   pars.vtype = repmat('c',1,pars.n);
   pars.bb = 'TwoS';
    
   % Solve the continuous relaxation to get a lower bound
   prob.f=c;
   prob.Aeq = pars.X.Aeq;
   prob.beq = pars.X.beq;
   prob.lb  = pars.X.lb;
   prob.ub  = pars.X.ub;
   prob.int = pars.vtype;
   Opt      = opti(prob);
   [pars.x0,pars.flow] = solve(Opt);

return
