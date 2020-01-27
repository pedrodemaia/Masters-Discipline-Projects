clear all
close all
clc

load('tempo.csv');
load('distancia.csv');

n = 250; % n�mero de cidades

% par�metros NSGA
P = 100; % tamanho da popula��o
tau = 0.5; % chance de muta��o
eta = 0.5; % fra��o da popula��o criada a partir de heur�stica construtiva
maxIter = 100; % n�mero m�ximo de itera��es
maxTime = 7200; % tempo m�ximo de execu��o

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