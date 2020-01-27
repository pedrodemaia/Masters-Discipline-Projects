% RUN(1) sem Localizer set
% RUN(2) com Localizer set
out = RUN(1);

x1 = out.sol(1:10)
y11 = out.sol(11:20);
y12 = out.sol(21:30);
y13 = out.sol(31:40);

demanda1 = [sum(y11) 13]
demanda2 = [sum(y12) 10]
demanda3 = [sum(y13) 6.5]

%any(out.sol < -1e-3)