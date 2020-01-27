classdef ILS
    properties
        TSP % problema TSP
        Alpha % parâmetro de aceitação no método de criação
        NumTestes % quantidade de testes na busca local
        MaxIter % número máximo de iterações
        MaxTime % Tempo máximo de execução
        RestartIterations % número de iterações para aceitar piora na solução
    end
    
    methods
        function ils = ILS(tsp,maxIter,maxTime,alpha,numTestes,restart)
            % tsp: uma instância do caixeiro viajante
            
            ils.TSP = tsp;
            ils.Alpha = alpha;
            ils.NumTestes = numTestes;
            ils.MaxIter = maxIter;
            ils.MaxTime = maxTime;
            ils.RestartIterations = restart;
        end
        
        function [xStar,fxStar,fxh,iter] = Optimize(ils)    
            % inicializa um solução usando heurística de Greedy
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
                
                % realiza permutação
                xNew = ils.TSP.CrossExchange(x);
                
                % aplica busca local
                [xLS,fxLS] = ils.TSP.ThreeOpt(xNew,ils.NumTestes);
                fxh = [fxh fxLS]; % armazena histórico de soluções
                
                if fxLS <= fxStar
                    % caso ache uma solução melhor, ela é usada
                    xStar = xLS;
                    fxStar = fxLS;
                    
                    x = xLS;
                    
                    noImprove = 0;
                elseif noImprove >= ils.RestartIterations
                    % se a solução é pior, mas atingiu o contador de
                    % restart, usa a nova solução
                    x = xLS;
                    noImprove = 0;
                else
                    % caso contrário incrementa contador de restart
                    noImprove = noImprove + 1;
                end
            end
            
            % realiza uma última busca local para refinar a solução
            [xf, fxf] = ils.TSP.TwoOptBestImprovement(xStar);
            if fxf < fxStar
                xStar = xf;
                fxStar = fxf;
            end
        end
    end
end