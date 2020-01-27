clear all
close all
clc

load('tempo.csv');

n = 250; % número de cidades
numTestes = 5;
rotasInvalidas = false;

% parâmetros GRASP
maxIterGrasp = 100000;
maxTimeGrasp = 7200;
alphaGrasp = 0.001;

% parâmetros ILS
maxIterILS = 100000;
maxTimeILS = 1800;
alphaILS = 0.001;
restartIters = 20;

tempoExecGRASP = zeros(1,numTestes);
timesGRASP = zeros(1,numTestes);
itersGRASP = zeros(1,numTestes);
xGRASP = zeros(numTestes,n);
fxhGRASP = cell(numTestes,1);

tempoExecILS = zeros(1,numTestes);
timesILS = zeros(1,numTestes);
itersILS = zeros(1,numTestes);
xILS = zeros(numTestes,n);
fxhILS = cell(numTestes,1);

load results.mat

for i = 1:numTestes
     tsp = TSP(tempo(1:n,1:n), rotasInvalidas);
    
    % executa o GRASP
    grasp = GRASP(tsp,maxIterGrasp,maxTimeGrasp,alphaGrasp,10*n);
    tic
    [xBestGRASP,fxBestGRASP,fxhGRASP{i},itersGRASP(i)] = grasp.Optimize;
    tempoExecGRASP(i) = toc
    timesGRASP(i) = fxBestGRASP
    xGRASP(i,:) = xBestGRASP;
    
    % executa o ILS
    ils = ILS(tsp,maxIterILS,maxTimeILS,alphaILS,10*n,restartIters);
    tic
    [xBestILS,fxBestILS,fxhILS{i},itersILS(i)] = ils.Optimize;
    tempoExecILS(i) = toc
    timesILS(i) = fxBestILS
    xILS(i,:) = xBestILS;
    
    save results.mat
end

[menorTempo,idBest] = min(timesGRASP(timesGRASP > 0));
rota = tsp.OrdenaRota(xGRASP(idBest,:));
[tempoAcumulado,tempoArestas] = tsp.tempoAcumulado(rota);

csvwrite('output.csv',[rota 1]);
% 
% figure;
% plot(fxhGRASP{idBest})
% title('Evolução das soluções encontradas')
% xlabel('Iteração')
% ylabel('Tempo da Rota')
% 
% figure;
% plot(tempoArestas,'.-')
% title('Tempo entre cidades')
% xlabel('Índice da cidade visitada')
% ylabel('Tempo da aresta')
% 
% figure;
% plot(tempoAcumulado,'.-')
% title('Tempo de viagem acumulado')
% xlabel('Índice da cidade visitada')
% ylabel('Tempo acumulado')