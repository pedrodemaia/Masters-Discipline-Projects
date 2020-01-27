clear all
close all
clc

load('tempo.csv');
load('distancia.csv');

n = 250; % número de cidades

% parâmetros NSGA
P = 100; % tamanho da população
tau = 0.5; % chance de mutação
eta = 0.5; % fração da população criada a partir de heurística construtiva
maxIter = 100; % número máximo de iterações
maxTime = 7200; % tempo máximo de execução

numTestes = 1;
tempoExec = zeros(1,numTestes);
iters = zeros(1,numTestes);
HV = zeros(10,numTestes);
Delta = zeros(10,numTestes);

for i = 1:numTestes
    tsp = TSP(tempo(1:n,1:n),distancia(1:n,1:n));
     
    % executa o NSGA
    nsga = NSGAII(tsp,P,tau,eta,maxIter,maxTime);
    tic
    [xBest,fxBest,xh,fxh,iters(i),delta,hv] = nsga.Optimize;
    Delta(:,i) = delta(:);
    HV(:,i) = hv(:);
    tempoExec(i) = toc
end