classdef TSP
    properties
        N % número de cidades
        Tempo % matriz de tempos entre cidades
        Distancia % matriz de distância entre cidades
        MetodoConstrutivo % heurística construtiva usada
    end
    
    methods
        function tsp = TSP(tempos,distancias)
            tsp.N = length(tempos);
            tsp.Tempo = tempos;
            tsp.Distancia = distancias;
            tsp.MetodoConstrutivo = 'Greedy';
        end
        
        function total = TempoTotal(tsp, x)
            if tsp.RotaValida(x)
                total = tsp.Tempo(x(end),x(1));
                for i=2:length(x)
                    total = total + tsp.Tempo(x(i-1),x(i));
                end
            else
                total = inf;
            end
        end
        
        function total = DistanciaTotal(tsp, x)
            if tsp.RotaValida(x)
                total = tsp.Distancia(x(end),x(1));
                for i=2:length(x)
                    total = total + tsp.Distancia(x(i-1),x(i));
                end
            else
                total = inf;
            end
        end
        
        function e = ExisteArco(tsp, origem, destino)
           e = tsp.Tempo(origem,destino) > 0 && ...
               tsp.Distancia(origem,destino) > 0;
        end
        
        function t = GetTempo(tsp, origem, destino)
            t = inf;
            if (tsp.ExisteArco(origem, destino))
               t = tsp.Tempo(origem,destino);
            end
        end
        
        function d = GetDistancia(tsp, origem, destino)
            d = inf;
            if (tsp.ExisteArco(origem, destino))
               d = tsp.Distancia(origem,destino);
            end
        end
        
        function v = RotaValida(tsp, x)
           v = ~isempty(x) && tsp.ExisteArco(x(end),x(1));
           if v
               for i=2:length(x)
                   v = tsp.ExisteArco(x(i-1),x(i));
                   if v == false
                       break;
                   end
               end
           end
        end
        
        function x = CriaRota(tsp)
           if strcmp(tsp.MetodoConstrutivo, 'NearestNeighbour')
                x = tsp.NearestNeightbour;
            elseif strcmp(tsp.MetodoConstrutivo, 'CheapestInsertion')
                x = tsp.CheapestInsertion;
            elseif strcmp(tsp.MetodoConstrutivo, 'Greedy')
                x = tsp.Greedy(0.2);
            else
                x = tsp.CriaRotaAleatoria;
           end
        end
        
        function x = CriaRotaAleatoria(tsp)
            x = randperm(tsp.N);
            while ~tsp.RotaValida(x)
                x = randperm(tsp.N);
            end
        end
        
        % cria um indivíduo usando a heurística do vizinho mais próximo
        function x = NearestNeightbour(tsp, wTime, wDist)
            x = [];
            
            tempos = tsp.Tempo;
            tempoMax = max(tempos(:));
            tempos(tempos==0) = 10*tempoMax;
            tempoMin = min(tempos(:));
            
            distancias = tsp.Distancia;
            distanciaMax = max(distancias(:));
            distancias(distancias==0) = 10*max(distancias(:));
            distanciaMin = min(distancias(:));
            
            value = wTime * tempos/(tempoMax - tempoMin) + ...
                wDist * distancias/(distanciaMax - distanciaMin);
            
            while (~tsp.RotaValida(x))
                x = [];
                V = 1:tsp.N;
                pos = randi(length(V));
                x(1,end+1) = V(pos);
                V(pos) = [];
                
                while any(V)
                    [~,index] = min(value(x(end),V));
                    x(1,end+1) = V(index);
                    V(index) = [];
                end
            end
        end
        
        % cria um indivíduo usando a heurística de Greedy
        function x = Greedy(tsp, alpha, wTime, wDist)
            x = [];
            
            tempos = tsp.Tempo;
            tempoMax = max(tempos(:));
            tempos(tempos==0) = 10*tempoMax;
            tempoMin = min(tempos(:));
            
            distancias = tsp.Distancia;
            distanciaMax = max(distancias(:));
            distancias(distancias==0) = 10*max(distancias(:));
            distanciaMin = min(distancias(:));
            
            value = wTime * tempos/(tempoMax - tempoMin) + ...
                wDist * distancias/(distanciaMax - distanciaMin);
            
            while (~tsp.RotaValida(x))
                x = [];
                V = 1:tsp.N;
                pos = randi(length(V));
                x(1,end+1) = V(pos);
                V(pos) = [];
                
                while any(V)
                    temposPossiveis = value(x(end),V);
                    Cmin = min(temposPossiveis);
                    Cmax = max(temposPossiveis);
                    maxValue = Cmin + alpha*(Cmax - Cmin);
                    L = V(temposPossiveis <= maxValue);
                    escolhido = randi(length(L));
                    [~,index] = find(V == L(escolhido));
                    x(1,end+1) = V(index);
                    V(index) = [];
                end
            end
        end
        
        % realiza cruzamento usando o Partially - Mapped Crossover
        function [xNew1,xNew2] = PMC(tsp,x1,x2)
            isValid = false;
            while ~isValid
                point = randi(tsp.N);
                xNew1 = x1;
                xNew2 = x2;
                
                for i=1:point
                    [~,pos1] = find(xNew1 ==x2(i));
                    [~,pos2] = find(xNew2 ==x1(i));
                    
                    xNew1([i,pos1]) = xNew1([pos1,i]);
                    xNew2([i,pos2]) = xNew2([pos2,i]);
                end
                
                isValid = tsp.RotaValida(xNew1) && tsp.RotaValida(xNew2);
            end
        end
        
        % Realiza um Cross-Exchange 4-opt para perturbar uma solução
        function [xNew,tempoNew,distNew] = CrossExchange(tsp,x)
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
                xNew = [x(1:a) x(f:g) x(d:e) x(b:c) x(h:end)];
                if tsp.RotaValida(xNew)
                    isValid = true;
                    tempoNew = tsp.TempoTotal(xNew);
                    distNew = tsp.DistanciaTotal(xNew);
                end
            end
        end
        
        function [xNew,tempoNew,distNew] = CrossExchange_n(tsp,x, n)
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
                    distNew = tsp.DistanciaTotal(xNew);
                end
            end
        end
        
        function [xNew,tempoNew,distNew] = SimpleSwap(tsp,x)
            isValid = false;
            while ~isValid
                i = randi(tsp.N-1);
                j = randi([i+1 tsp.N]);
                xNew = x;
                xNew(i:j) = x(j:-1:i);
                if tsp.RotaValida(xNew)
                    isValid = true;
                    tempoNew = tsp.TempoTotal(xNew);
                    distNew = tsp.DistanciaTotal(xNew);
                end
            end
        end
        
        function rotaOrdenada = OrdenaRota(~, rota)
            id = find(rota==1);
            rotaOrdenada = [rota(id:end) rota(1:id-1)];
        end
        
        function isEqual = IsRouteEqual(tsp, rota1, rota2)
            isEqual = all(tsp.OrdenaRota(rota1)==tsp.OrdenaRota(rota2));
        end
        
    end
end