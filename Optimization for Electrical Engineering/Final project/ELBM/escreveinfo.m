function escreveinfo(fid,k,nbun,f,c,E,cpu,ncall,flow)
%{
if nargin==1
    fprintf(fid,'%3s   %3s   %3s   %11s     %12s     %12s  %20s \n',...
                 'k', '|J|',  'call',  'f(x)',  'c(x)',  'Ok', 'cpu');
else
   fprintf(fid,'%3d   %3d  %3d  %15.8f   %15.8f  %15.8f  %20.8f \n',...
                k,   nbun,  ncall,   f,      c,      E,     cpu);
end
%}
   fprintf(fid,'k: %3d   Bun: %3d  Call: %3d flow: %4.1d f: %4.1d   c: %4.1d  hk :%4.1d  cpu :%5.1f \n',...
                k,   nbun,  ncall,  flow, f,      c,      E,     cpu);
return