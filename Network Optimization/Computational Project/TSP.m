classdef TSP
    properties
        N % número de cidades
        T % matriz de tempos entre cidades
        MetodoConstrutivo % heurística construtiva usada
        ArcosInexistentes % conjunto de arcos inexistentes
        ConsiderarRotasInvalidas % considera rotas com tempo 0 inválidas ou não
    end
    
    methods
        function tsp = TSP(tempos, rotasInvalidas)
            tsp.N = length(tempos);
            tsp.T = tempos;
            tsp.MetodoConstrutivo = 'Greedy';
            tsp.ConsiderarRotasInvalidas = rotasInvalidas;
            tsp.ArcosInexistentes = tsp.GetArcosInexistentes;
        end
        
        function total = TempoTotal(tsp, ind)
            if tsp.IndividuoValido(ind)
                total = tsp.T(ind(end),ind(1));
                for i=2:length(ind)
                    total = total + tsp.T(ind(i-1),ind(i));
                end
            else
                total = inf;
            end
        end
        
        function [acumulado,incremento] = tempoAcumulado(tsp, ind)
            acumulado = 0;
            incremento = [];
            if tsp.IndividuoValido(ind)
                for i=2:length(ind)
                    incremento(1,end+1) = tsp.T(ind(i-1),ind(i));
                    acumulado(1,end+1) = acumulado(end) + incremento(end);
                end
                incremento(1,end+1) = tsp.T(ind(end),ind(1));
                acumulado(1,end+1) = acumulado(end) + incremento(end);
            else
                acumulado(1,end+1) = inf;
            end
            acumulado = acumulado(2:end);
            %incremento = [incremento(2:end) incremento(1)];
            %acumulado = [acumulado(2:end) acumulado(1)];
        end
        
        function e = ExisteArco(tsp, origem, destino)
           if ~tsp.ConsiderarRotasInvalidas
               e = true;
               return
           end
           e = tsp.T(origem,destino) > 0;
        end
        
        function t = GetTempo(tsp, origem, destino)
            t = inf;
            if (tsp.ExisteArco(origem, destino))
               t = tsp.T(origem,destino);
            end
        end
        
        function v = IndividuoValido(tsp, ind)
           v = ~isempty(ind) && tsp.ExisteArco(ind(end),ind(1));
           if ~tsp.ConsiderarRotasInvalidas
               return
           end
           if v
               for i=2:length(ind)
                   v = tsp.ExisteArco(ind(i-1),ind(i));
                   if v == false
                       break;
                   end
               end
           end
        end
        
        function arcosInexistentes = GetArcosInexistentes(tsp)
            arcosInexistentes = [];
            for i=1:tsp.N
                for j=i+1:tsp.N
                    if tsp.T(i,j) == 0
                        arcosInexistentes(end+1,1:2) = [i j];
                    end
                end
            end
        end
        
        function ind = CriaIndividuo(tsp)
           if strcmp(tsp.MetodoConstrutivo, 'NearestNeighbour')
                ind = tsp.NearestNeightbour;
            elseif strcmp(tsp.MetodoConstrutivo, 'CheapestInsertion')
                ind = tsp.CheapestInsertion;
            elseif strcmp(tsp.MetodoConstrutivo, 'Greedy')
                ind = tsp.Greedy(0.2);
            else
                ind = tsp.CriaIndividuoAleatorio;
           end
        end
        
        function ind = CriaIndividuoAleatorio(tsp)
            ind = randperm(tsp.N);
            while ~tsp.IndividuoValido(ind)
                ind = randperm(tsp.N);
            end
        end
        
        % cria um indivíduo usando a heurística do vizinho mais próximo
        function ind = NearestNeightbour(tsp)
            ind = [];
            
            tempos = tsp.T;
            if tsp.ConsiderarRotasInvalidas
                tempos(tempos==0) = inf;
            end
            
            while (~tsp.IndividuoValido(ind))
                ind = [];
                V = 1:tsp.N;
                pos = randi(length(V));
                ind(1,end+1) = V(pos);
                V(pos) = [];
                
                while any(V)
                    [~,index] = min(tempos(ind(end),V));
                    ind(1,end+1) = V(index);
                    V(index) = [];
                end
            end
        end
        
        % cria um indivíduo usando a heurística da inserção mais barata
        function ind = CheapestInsertion(tsp)
            V = 1:tsp.N;
            ind = [];
            
            pos1 = randi(length(V));
            ind(1,end+1) = V(pos1);
            V(pos1) = [];
            
            valid = false;
            while ~valid
                pos2 = randi(length(V));
                cidade2 = V(pos2);
                if (tsp.ExisteArco(ind(1),cidade2))
                    ind(1,end+1) = cidade2;
                    V(pos2) = [];
                    valid = true;
                end
            end
            
            while any(V)
                pos = randi(length(V));
                cidade = V(pos);
                n = length(ind);
                temps = inf(n+1,1);
                if(tsp.ExisteArco(cidade,ind(1)))
                    temps(1) = tsp.TempoTotal([cidade ind]);
                end
                if(tsp.ExisteArco(ind(end),cidade))
                    temps(end) = tsp.TempoTotal([ind cidade]);
                end
                
                for i=1:n-1
                    if (tsp.ExisteArco(ind(i),cidade) && ...
                            tsp.ExisteArco(cidade,ind(i+1)))
                        temps(i+1) = (tsp.TempoTotal([ind(1:i) cidade ind(i+1:end)]));
                    end
                end
                
                [minTempo,id] = min(temps);
                if (~isinf(minTempo))
                    V(pos) = [];
                    if (id == 1)
                        ind = [cidade ind];
                    else
                        if (id == length(temps))
                            ind(end+1) = cidade;    
                        else
                            ind = [ind(1:id-1) cidade ind(id:end)];
                        end
                    end
                end
            end
        end
        
        % cria um indivíduo usando a heuística de Greedy
        function ind = Greedy(tsp, alpha)
            ind = [];
            
            tempos = tsp.T;
            if tsp.ConsiderarRotasInvalidas
                tempoMax = max(tempos(:));
                tempos(tempos==0) = 10*tempoMax;
            end
            
            while (~tsp.IndividuoValido(ind))
                ind = [];
                V = 1:tsp.N;
                pos = randi(length(V));
                ind(1,end+1) = V(pos);
                V(pos) = [];
                
                while any(V)
                    temposPossiveis = tempos(ind(end),V);
                    Cmin = min(temposPossiveis);
                    Cmax = max(temposPossiveis);
                    maxValue = Cmin + alpha*(Cmax - Cmin);
                    L = V(temposPossiveis <= maxValue);
                    escolhido = randi(length(L));
                    [~,index] = find(V == L(escolhido));
                    ind(1,end+1) = V(index);
                    V(index) = [];
                end
            end
        end
        
        %% Métodos de busca local
        function [indStar,tempoStar] = TwoOpt(tsp,ind0,nTestes)
            tempoStar = inf;
            indStar = [];
            
            tempoBest = tsp.TempoTotal(ind0);
            indBest = ind0;
            ind = ind0;
            
            improved = true;
            while improved
                improved = false;
                for teste = 1:nTestes
                        i = randi(tsp.N-1);
                        j = randi([i+1 tsp.N]);
                        indAux = ind;
                        indAux(i:j) = ind(j:-1:i);
                        if tsp.IndividuoValido(indAux)
                            tempoAux = tsp.TempoTotal(indAux);
                            if tempoAux < tempoStar
                                tempoStar = tempoAux;
                                indStar = indAux;
                            end
                            if tempoAux < tempoBest
                                improved = true;
                                indBest = indAux;
                                tempoBest = tempoAux;
                            end
                        end
                end
                ind = indBest;
            end
        end
        
        function [indStar,tempoStar] = TwoOptFirstImprovement(tsp,ind0)
            tempoStar = inf;
            indStar = [];
            
            tempoBest = tsp.TempoTotal(ind0);
            indBest = ind0;
            ind = ind0;
            
            improved = true;
            while improved
                improved = false;
                shouldBreak = false;
                for i = 1:(tsp.N-1)
                    if shouldBreak
                        break;
                    end
                    for j = (i+1):tsp.N
                        indAux = ind;
                        indAux(i:j) = ind(j:-1:i);
                        if tsp.IndividuoValido(indAux)
                            tempoAux = tsp.TempoTotal(indAux);
                            if tempoAux < tempoStar
                                tempoStar = tempoAux;
                                indStar = indAux;
                            end
                            if tempoAux < tempoBest
                                improved = true;
                                indBest = indAux;
                                tempoBest = tempoAux;
                                shouldBreak = true;
                                break;
                            end
                        end
                    end
                end
                ind = indBest;
            end
        end
        
        function [indStar,tempoStar] = TwoOptBestImprovement(tsp,ind0)
            tempoStar = inf;
            indStar = [];
            
            tempoBest = tsp.TempoTotal(ind0);
            indBest = ind0;
            ind = ind0;
            
            improved = true;
            while improved
                improved = false;
                for i = 1:(tsp.N-1)
                    for j = (i+1):tsp.N
                        indAux = ind;
                        indAux(i:j) = ind(j:-1:i);
                        if tsp.IndividuoValido(indAux)
                            tempoAux = tsp.TempoTotal(indAux);
                            if tempoAux < tempoStar
                                tempoStar = tempoAux;
                                indStar = indAux;
                            end
                            if tempoAux < tempoBest
                                improved = true;
                                indBest = indAux;
                                tempoBest = tempoAux;
                            end
                        end
                    end
                end
                ind = indBest;
            end
        end
        
        function [indStar,tempoStar] = ThreeOpt(tsp,ind0,nTestes)
            tempoStar = inf;
            indStar = [];
            
            tempoBest = tsp.TempoTotal(ind0);
            indBest = ind0;
            ind = ind0;
            
            improved = true;
            while improved
                improved = false;
                for teste = 1:nTestes
                    i = randi(tsp.N-6);
                    j = randi([i+2 tsp.N-4]);
                    k = randi([j+2 tsp.N-1]);
                    % sub-tours criados
                    t1 = ind(1:i);
                    t2 = ind(i+1:j);
                    t3 = ind(j+1:k);
                    t4 = ind(k+1:end);
                    inds = [t1 t2 t3(end:-1:1) t4;
                        t1 t2(end:-1:1) t3 t4;
                        t1 t2(end:-1:1) t3(end:-1:1) t4;
                        t1 t3 t2 t4;
                        t1 t3 t2(end:-1:1) t4;
                        t1 t3(end:-1:1) t2 t4;
                        t1 t3(end:-1:1) t2(end:-1:1) t4;];
                    
                    for l = 1:7
                        indAux = inds(l,:);
                        if tsp.IndividuoValido(indAux)
                            tempoAux = tsp.TempoTotal(indAux);
                            if tempoAux < tempoStar
                                tempoStar = tempoAux;
                                indStar = indAux;
                            end
                            if tempoAux < tempoBest
                                improved = true;
                                indBest = indAux;
                                tempoBest = tempoAux;
                            end
                        end
                    end
                    ind = indBest;
                end
            end
        end
        
        function [indStar,tempoStar] = ThreeOptFirstImprovement(tsp,ind0)
            tempoStar = inf;
            indStar = [];
            
            tempoBest = tsp.TempoTotal(ind0);
            indBest = ind0;
            ind = ind0;
            
            improved = true;
            while improved
                improved = false;
                shouldBreak = false;
                for i = 1:tsp.N-6
                    if shouldBreak
                        break;
                    end
                    for j = (i+2):tsp.N-4   
                        if shouldBreak
                            break;
                        end
                        for k = (j+2):tsp.N-1
                            if shouldBreak
                                break;
                            end
                            % sub-tours criados
                            t1 = ind(1:i);
                            t2 = ind(i+1:j);
                            t3 = ind(j+1:k);
                            t4 = ind(k+1:end);
                            inds = [t1 t2 t3(end:-1:1) t4;
                                    t1 t2(end:-1:1) t3 t4;
                                    t1 t2(end:-1:1) t3(end:-1:1) t4;
                                    t1 t3 t2 t4;
                                    t1 t3 t2(end:-1:1) t4;
                                    t1 t3(end:-1:1) t2 t4;
                                    t1 t3(end:-1:1) t2(end:-1:1) t4;];

                            for l = 1:7
                                indAux = inds(l,:);
                                if tsp.IndividuoValido(indAux)
                                    tempoAux = tsp.TempoTotal(indAux);
                                    if tempoAux < tempoStar
                                        tempoStar = tempoAux;
                                        indStar = indAux;
                                    end
                                    if tempoAux < tempoBest
                                        improved = true;
                                        indBest = indAux;
                                        tempoBest = tempoAux;
                                        shouldBreak = true;
                                    end
                                end
                            end
                        end
                    end
                end
                ind = indBest;
            end
        end
        
        function [indStar,tempoStar] = ThreeOptBestImprovement(tsp,ind0)
            tempoStar = inf;
            indStar = [];
            
            tempoBest = tsp.TempoTotal(ind0);
            indBest = ind0;
            ind = ind0;
            
            improved = true;
            while improved
                improved = false;
                for i = 1:tsp.N-6
                    for j = (i+2):tsp.N-4
                        for k = (j+2):tsp.N-1
                            % sub-tours criados
                            t1 = ind(1:i);
                            t2 = ind(i+1:j);
                            t3 = ind(j+1:k);
                            t4 = ind(k+1:end);
                            inds = [t1 t2 t3(end:-1:1) t4;
                                    t1 t2(end:-1:1) t3 t4;
                                    t1 t2(end:-1:1) t3(end:-1:1) t4;
                                    t1 t3 t2 t4;
                                    t1 t3 t2(end:-1:1) t4;
                                    t1 t3(end:-1:1) t2 t4;
                                    t1 t3(end:-1:1) t2(end:-1:1) t4;];

                            for l = 1:7
                                indAux = inds(l,:);
                                if tsp.IndividuoValido(indAux)
                                    tempoAux = tsp.TempoTotal(indAux);
                                    if tempoAux < tempoStar
                                        tempoStar = tempoAux;
                                        indStar = indAux;
                                    end
                                    if tempoAux < tempoBest
                                        improved = true;
                                        indBest = indAux;
                                        tempoBest = tempoAux;
                                    end
                                end
                            end
                        end
                    end
                end
                ind = indBest;
            end
        end
        
        function [indNew,tempoNew] = CrossExchange(tsp,ind)
            isValid = false;
            while ~isValid
                a = randi(tsp.N-8);
                b = a+1;
                c = randi([b+1 tsp.N-6]);
                d = c+1;
                e = randi([d+1 tsp.N-4]);
                f = e+1;
                g = randi([f+1 tsp.N-2]);
                h = g+1;
                indNew = [ind(1:a) ind(f:g) ind(d:e) ind(b:c) ind(h:end)];
                if tsp.IndividuoValido(indNew)
                    isValid = true;
                    tempoNew = tsp.TempoTotal(indNew);
                end
            end
        end
        
        function [xNew,tempoNew] = CrossExchange_n(tsp,x, n)
            isValid = false;
            while ~isValid
                pos = sort(randperm(floor(tsp.N/2),n))*2-1;
                xNew = [x(1:pos(1)) x(pos(end)+1:end)];
                for i = 1:(n/2)-1
                    xNew = [xNew x(pos(i)+1:pos(i+1)) x(pos(end-i)+1:pos(end-i+1))];
                end
                xNew = [xNew x(pos(i+1)+1:pos(i+2))];
                
                if tsp.RotaValida(xNew)
                    isValid = true;
                    tempoNew = tsp.TempoTotal(xNew);
                end
            end
        end
        
        function [indNew,tempoNew] = SimpleSwap(tsp,ind)
            isValid = false;
            while ~isValid
                i = randi(tsp.N-1);
                j = randi([i+1 tsp.N]);
                indNew = ind;
                indNew(i:j) = ind(j:-1:i);
                if tsp.IndividuoValido(indNew)
                    isValid = true;
                    tempoNew = tsp.TempoTotal(indNew);
                end
            end
        end
        
        function rotaOrdenada = OrdenaRota(~, rota)
            id = find(rota==1);
            rotaOrdenada = [rota(id:end) rota(1:id-1)];
        end
    end
end