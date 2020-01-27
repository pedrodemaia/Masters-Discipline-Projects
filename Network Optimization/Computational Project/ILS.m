classdef ILS
    properties
        TSP % problema TSP
        Alpha % par�metro de aceita��o no m�todo de cria��o
        NumTestes % quantidade de testes na busca local
        MaxIter % n�mero m�ximo de itera��es
        MaxTime % Tempo m�ximo de execu��o
        RestartIterations % n�mero de itera��es para aceitar piora na solu��o
    end
    
    methods
        function ils = ILS(tsp,maxIter,maxTime,alpha,numTestes,restart)
            % tsp: uma inst�ncia do caixeiro viajante
            
            ils.TSP = tsp;
            ils.Alpha = alpha;
            ils.NumTestes = numTestes;
            ils.MaxIter = maxIter;
            ils.MaxTime = maxTime;
            ils.RestartIterations = restart;
        end
        
        function [xStar,fxStar,fxh,iter] = Optimize(ils)    
            % inicializa um solu��o usando heur�stica de Greedy
            x = ils.TSP.Greedy(ils.Alpha);
            fx = ils.TSP.TempoTotal(x);
            
            xStar = x;
            fxStar = fx;
            
            % realiza primeira busca local
            [xLS,fxLS] = ils.TSP.ThreeOpt(x,ils.NumTestes);
            if fxLS <= fxStar
                xStar = xLS;
                fxStar = fxLS;
            end
            
            fxh = fxStar;
            
            x = xStar;
            
            noImprove = 0;
            iter = 0;
            tstart = tic;
            while iter <= ils.MaxIter && toc(tstart) < ils.MaxTime
                iter = iter + 1;
                
                % realiza permuta��o
                xNew = ils.TSP.CrossExchange(x);
                
                % aplica busca local
                [xLS,fxLS] = ils.TSP.ThreeOpt(xNew,ils.NumTestes);
                fxh = [fxh fxLS]; % armazena hist�rico de solu��es
                
                if fxLS <= fxStar
                    % caso ache uma solu��o melhor, ela � usada
                    xStar = xLS;
                    fxStar = fxLS;
                    
                    x = xLS;
                    
                    noImprove = 0;
                elseif noImprove >= ils.RestartIterations
                    % se a solu��o � pior, mas atingiu o contador de
                    % restart, usa a nova solu��o
                    x = xLS;
                    noImprove = 0;
                else
                    % caso contr�rio incrementa contador de restart
                    noImprove = noImprove + 1;
                end
            end
            
            % realiza uma �ltima busca local para refinar a solu��o
            [xf, fxf] = ils.TSP.TwoOptBestImprovement(xStar);
            if fxf < fxStar
                xStar = xf;
                fxStar = fxf;
            end
        end
    end
end