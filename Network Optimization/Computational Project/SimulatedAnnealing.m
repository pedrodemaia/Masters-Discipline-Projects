classdef SimulatedAnnealing
    properties
        TSP % problema TSP
        alpha % fator de redução de temperatura
        tau % fator de aceitação
        rStop % critério de parada: número de reduções de temperatura sem melhora
    end
    
    methods
        function sa = SimulatedAnnealing(tsp,alpha,tau,rStop)
            % tsp: uma instância do caixeiro viajante
            
            sa.TSP = tsp;
            sa.alpha = alpha;
            sa.tau = tau;
            sa.rStop = rStop;
        end
        
        function [xStar,fxStar] = Optimize(sa,x0)
            t = sa.GetInitialTemperature(x0);
            xStar = x0;
            fxStar = sa.TSP.TempoTotal(x0);
            
            x = xStar;
            fx = fxStar;
            reductions = 0;
            totalIter = 0;
            while reductions <= sa.rStop
                totalIter = totalIter + 1
                reductions = reductions + 1
                iter = 0;
                accepted = 0;
                while accepted < 12/12*sa.TSP.N && iter < 100/10*sa.TSP.N
                    iter = iter + 1;
                    
                    [xNew,fxNew] = sa.TSP.TwoOpt(x,ceil(0.4*sa.TSP.N));
                    %[xNew,fxNew] = sa.TSP.TwoOpt(x,50);
                    if fxNew < fx
                        accepted = accepted + 1;
                        x = xNew;
                        xBest = xNew;
                        fx = fxNew;
                    elseif exp(-(fxNew-fx)/t) > rand
                        accepted = accepted + 1;
                        x = xNew;
                    end
                end
                t = sa.alpha * t;
                if fx < fxStar
                    reductions = 0;
                    xStar = xBest;
                    fxStar = fx;
                end
            end
        end
        
        function t0 = GetInitialTemperature(sa,x0)
            E0 = sa.TSP.TempoTotal(x0);
            n = 100;
            E = zeros(n,1);
            for i=1:n
                [~,E(i)] = sa.TSP.SimpleSwap(x0);
            end
            t0 = 1*-mean(abs(E-E0))/log(sa.tau);
        end
    end
end