classdef GRASP
    properties
        TSP % problema TSP
        Alpha % parâmetro de aceitação no método de criação
        NumTestes % quantidade de testes na busca local
        MaxIter % número máximo de iterações
        MaxTime % tempo máximo de execução
    end
    
    methods
        function grasp = GRASP(tsp,maxIter,maxTime,alpha,numTestes)
            % tsp: uma instância do caixeiro viajante
            
            grasp.TSP = tsp;
            grasp.MaxIter = maxIter;
            grasp.MaxTime = maxTime;
            grasp.Alpha = alpha;
            grasp.NumTestes = numTestes;
        end
        
        function [xStar,fxStar,fxh,iter] = Optimize(grasp)
            xStar = [];
            fxStar = inf;
            fxh = [];
            
            iter = 0;
            tstart = tic;
            while iter <= grasp.MaxIter && toc(tstart) < grasp.MaxTime
                iter = iter + 1;
                
                x = grasp.TSP.Greedy(grasp.Alpha);
                fx = grasp.TSP.TempoTotal(x);
                
                if fx <= fxStar
                    xStar = x;
                    fxStar = fx;
                end
                
                [xLS,fxLS] = grasp.TSP.ThreeOpt(x,grasp.NumTestes);
                fxh = [fxh fxLS]; % armazena histórico de soluções
                
                if fxLS <= fxStar
                    xStar = xLS;
                    fxStar = fxLS;
                end
            end
            
            % realiza uma última busca local para refinar a solução
            [xf, fxf] = grasp.TSP.TwoOptBestImprovement(xStar);
            if fxf < fxStar
                xStar = xf;
                fxStar = fxf;
            end
        end
    end
end