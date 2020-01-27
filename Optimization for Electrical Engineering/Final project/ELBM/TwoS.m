function [f,gf,c,gc] = TwoS(pars)
%
Ncen = pars.Ncen;
seed = pars.seed;
x    = pars.x;
[hm,qm,W,T,~,c,~,sigmah,sigmaq]= feval(pars.problem);
gf           = c;
f            = c'*x; 
icen         = 0;
%
randn('state',seed);
rand('state',seed);
n2 = length(qm);
m2 = length(hm);
%
while (icen<Ncen)
    icen = icen + 1;
    h = max(hm + randn(m2,1).*sigmah, 0);
    %h = hm + randn(m2,1).*sigmah;
    q = max(qm + randn(n2,1).*sigmaq, 0);
    b = -(h-T*x);
    options = optimset('linprog');
    options.Display = 'off';
    %[ui,vi,e] = linprog(q,[],[],W,h - T*x,zeros(numel(q),1),[]);
    [ui,vi,e] = linprog(b,W',q,[],[],zeros(numel(b),1),[],options);
    if e<0
        disp('Problemas na resolucao do PL');
        continue
    end
    gf          = gf - (T'*ui)/Ncen;    
    f           = f  -  vi/Ncen;
end
c=[];gc=[];
return
