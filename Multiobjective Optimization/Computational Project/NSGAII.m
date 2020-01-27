classdef NSGAII
    properties
        TSP % problema TSP
        P % tamanho da população
        Tau % chance de mutação
        Eta % chance de usar heurística construtiva na criação da população
        MaxIter % número máximo de iterações
        MaxTime % tempo máximo de execução
        Utopico % utopic point
        Nadir % anti-utopic point
    end
    
    methods
        function nsga = NSGAII(tsp,p,tau,eta,maxIter,maxTime)
            nsga.TSP = tsp;
            nsga.P = p;
            nsga.Tau = tau;
            nsga.Eta = eta;
            nsga.MaxIter = maxIter;
            nsga.MaxTime = maxTime;
            nsga.Utopico = [29.4 1572.6];
            nsga.Nadir = [36.9 2408.5];
        end
        
        function [xStar,fxStar,xh,fxh,iter,Delta,HV] = Optimize(nsga)
            % inicialização das métricas
            Delta = zeros(1,10);
            HV = zeros(1,10);
            iMetric = 0;
            metricIters = round(linspace(0,nsga.MaxIter,11));
            
            % inicialização
            [P fxh] = nsga.CreateInitialPopulation;
            Q = [];
            
            % histórico de soluções
            xh = P;
            
            iter = 0;
            tStart = tic;
            while iter < nsga.MaxIter && toc(tStart) < nsga.MaxTime
                iter = iter + 1;
                
                % agrupa pais e offspring
                R = [P; Q];
                
                % calcula os fronts de não dominância
                F = nsga.FastNonDominatedSort(R);
                
                cDist = cell(size(F,1),1);
                P = [];
                rank = 1;
                
                % gera população com base nos ranknings de não dominância
                while rank <= numel(F) && ...
                        size(P,1) + size(F{rank},1) <= nsga.P
                    % calcula Crowding Distance para aquele front
                    cDist{rank} = nsga.CrowdingDistanceAssignment(F{rank});
                    P = [P; F{rank}];
                    rank = rank + 1;
                end
                
                % completa a população com as melhores solução do fronte
                % seguinte com base na Crowding Distance
                if size(P,1) < nsga.P
                    cDist{rank} = nsga.CrowdingDistanceAssignment(F{rank});
                    [~,order] = sort(cDist{rank},'descend');
                    n = nsga.P - size(P,1);
                    F{rank} = F{rank}(order(1:n),:);
                    cDist{rank} = cDist{rank}(order(1:n));
                    P = [P; F{rank}];
                end
                
                % remove ranks não usados
                if numel(cDist) < numel(F)
                    F = F(1:numel(cDist));
                end
                
                % Gera offspring
                Q = nsga.MakeNewPopulation(F,cDist);
                
                % armazena soluções
                xh = [xh; P];
                newfxh = zeros(size(P,1),2);
                for i=1:size(newfxh,1)
                    newfxh(i,:) = [nsga.TSP.TempoTotal(P(i,:)) ...
                        nsga.TSP.DistanciaTotal(P(i,:))];
                end
                fxh = [fxh; newfxh];
                
                firstFront = F{1};
                fxFront = zeros(size(firstFront,1),2);
                for i=1:size(fxFront,1)
                    fxFront(i,:) = [nsga.TSP.TempoTotal(firstFront(i,:))...
                        nsga.TSP.DistanciaTotal(firstFront(i,:))];
                end
                
                if any(metricIters == iter)
                    iMetric = iMetric + 1;
                    HV(iMetric) = nsga.Hipervolume(fxFront);
                    Delta(iMetric) = nsga.DeltaMeasure(fxFront);
                end
                
                plot(fxh(:,1),fxh(:,2),'bx');
                hold on;
                plot(fxFront(:,1),fxFront(:,2),'ro');
                title(['Geração = ' num2str(iter)])
                xlabel('Tempo')
                ylabel('Distância')
                drawnow;
                hold off;
            end
            
            xStar = F{1};
            nPareto = size(xStar,1);
            fxStar = zeros(nPareto,2);
            for i=1:nPareto
                fxStar(i,:) = [nsga.TSP.TempoTotal(xStar(i,:)) ...
                    nsga.TSP.DistanciaTotal(xStar(i,:))];
            end
        end
        
        function [xNew] = MakeNewPopulation(nsga,front,dist)
            numRanks = numel(front);
            
            population = cell2mat(front');
            
            xNew = zeros(nsga.P,nsga.TSP.N);
            for i=1:2:nsga.P
                isValid = false;
                while ~isValid
                    x = zeros(2,nsga.TSP.N);                

                    for s=1:2
                        r1 = randi(numRanks);
                        r2 = randi(numRanks);
                        if r1 == r2
                            f = front{r1};
                            d = dist{r1};
                            if numel(d) > 1
                                pos = randperm(numel(d),2);
                                [~,id] = max(d(pos));
                            else
                                pos = 1;
                                id = 1;
                            end
                            x(s,:) = f(pos(id),:);
                        else
                            r = min([r1 r2]);
                            f = front{r};
                            x(s,:) = f(randi(size(f,1)),:);
                        end
                    end

                    % cruzamento
                    [xNew(i,:), xNew(i+1,:)] = nsga.TSP.PMC(x(1,:),x(2,:));

                    % mutação
                    for j=1:2
                        if (rand < nsga.Tau)
                            %xNew(i+j-1,:) = nsga.TSP.CrossExchange( ...
                            %    xNew(i+j-1,:));
                            xNew(i+j-1,:) = nsga.TSP.CrossExchange_n( ...
                                xNew(i+j-1,:),floor(nsga.TSP.N/5));
                        end
                    end
                    
                    allPopoulation = [population; xNew(1:i-1,:)];
                    isValid = ~nsga.IsRoutInPopulation(xNew(i,:),allPopoulation) && ...
                        ~nsga.IsRoutInPopulation(xNew(i+1,:),allPopoulation);
                end
            end
        end
        
        function [x, fx] = CreateInitialPopulation(nsga)
            tsp = nsga.TSP;
            
            limit = nsga.Eta;
            
            x = zeros(nsga.P,tsp.N);
            fx = zeros(nsga.P,2);
            
            heuristica = round(nsga.P * nsga.Eta);
            p = linspace(0.01,0.99,heuristica);
            
            for i=1:heuristica
                xi = tsp.Greedy(0.0, p(i), 1 - p(i));
                x(i,:) = xi;
                fx(i,:) = [tsp.TempoTotal(xi) tsp.DistanciaTotal(xi)];
            end
            for i=heuristica+1:nsga.P
                xi = tsp.CriaRotaAleatoria;
                x(i,:) = xi;
                fx(i,:) = [tsp.TempoTotal(xi) tsp.DistanciaTotal(xi)];
            end
%             for i=1:nsga.P
%                 chance = rand;
%                 if chance > limit
%                     xi = tsp.CriaRotaAleatoria;
%                 elseif chance < limit/2
%                     xi = tsp.Greedy(0.0, 0.99, 0.01);
%                 else
%                     xi = tsp.Greedy(0.0, 0.01, 0.99);
%                 end
%                 x(i,:) = xi;
%                 fx(i,:) = [tsp.TempoTotal(xi) tsp.DistanciaTotal(xi)];
%             end
        end
        
        function [front] = FastNonDominatedSort(nsga, x)
            n = size(x,1);
            S = cell(n,1);
            eta = zeros(n,1);
            rank = zeros(n,1);
            front{1} = [];
            frontid{1} = [];
            
            for p=1:n
                S{p} = [];
                xp = x(p,:);
                for q=1:n
                    if p == q
                        continue;
                    end
                    xq = x(q,:);
                    if nsga.Domina(xp,xq)
                        S{p} = [S{p} q];
                    elseif nsga.Domina(xq,xp)
                        eta(p) = eta(p) + 1;
                    end
                end
                if eta(p) == 0
                    rank(p) = 1;
                    front{1} = [front{1}; xp];
                    frontid{1} = [frontid{1} p];
                end
            end
            
            i = 1;
            while ~isempty(front{i})
                Q = [];
                Qid = [];
                for p=frontid{i}
                    for q=S{p}
                        eta(q) = eta(q) - 1;
                        if eta(q) == 0
                            rank(q) = i+1;
                            Q = [Q; x(q,:)];
                            Qid = [Qid q];
                        end
                    end
                end
                i = i+1;
                front{i} = Q;
                frontid{i} = Qid;
            end
            
            front = front(1:end-1);
        end
        
        function d = CrowdingDistanceAssignment(nsga,x)
            n = size(x,1);
            fx = zeros(n,2);
            for i=1:n
                fx(i,:) = [nsga.TSP.TempoTotal(x(i,:)), ...
                    nsga.TSP.DistanciaTotal(x(i,:))];
            end
            fxMin = min(fx);
            fxMax = max(fx);
            
            d = zeros(1,n);
            for m=1:size(fx,2)
                [~,order] = sort(fx(:,m));
                d(order(1)) = inf;
                d(order(end)) = inf;
                for i=2:n-1
                    d(order(i)) = d(order(i)) + ...
                        (fx(order(i+1)) - fx(order(i-1)))/(fxMax(m) - fxMin(m));
                    if isnan(d(order(i)))
                        d(order(i)) = 0;
                    end
                end
            end
        end
        
        function d = Domina(nsga,x1,x2)
            e = 0.0;
            
            t1 = nsga.TSP.TempoTotal(x1);
            t2 = nsga.TSP.TempoTotal(x2);
            
            d1 = nsga.TSP.DistanciaTotal(x1);
            d2 = nsga.TSP.DistanciaTotal(x2);
            d = d1 - e <= d2 && t1 - e <= t2;
        end
        
        function rotasDiferentes = GetRotasDistintas(nsga, front)
            rotasDiferentes = [];
            for i = 1:size(front,1)
                isEqual = false;
                for j = i+1:size(front,1)
                    isEqual = nsga.TSP.IsRouteEqual(front(i,:),front(j,:));
                    if isEqual
                        break;
                    end
                end
                if ~isEqual 
                    rotasDiferentes = [rotasDiferentes; front(i,:)];
                end
            end
        end
        
        function isEqual = IsRoutInPopulation(nsga, rota, population)
            isEqual = false;
            for i = 1:size(population,1)
                isEqual = nsga.TSP.IsRouteEqual(population(i,:),rota);
                if isEqual
                    break;
                end
            end
        end
        
        % indicadores de qualidade
        function delta = DeltaMeasure(nsga, pareto)     
            % numero de pontos
            n = size(pareto,1);
            
            if n ==1
               delta = 0;
               return;
            end
            
            % pareto normalizado
            normPareto = pareto;
            %normPareto = [normalize(pareto(:,1),'norm',2) ...
            %    normalize(pareto(:,2),'norm',2)];
            
            % ponto utópico
            AStar = nsga.Utopico;
            
            di = zeros(n,1);
            de1 = zeros(n,1);
            de2 = zeros(n,1);
            for i=1:n
                de1(i) = normPareto(i,1) - AStar(1);
                de2(i) = normPareto(i,2) - AStar(2);
                diTemp = [];
                for j=1:n
                   if i == j
                       continue;
                   end
                   diTemp(end+1,1) = nsga.GetDistance(normPareto(i,:),normPareto(j,:));
                end
                di(i) = min(diTemp);
            end
            
            dMean = mean(di);
            
            deMin = min(de1) + min(de2);
            
            delta = (deMin + sum(abs(di-dMean)))/(deMin + n*dMean);
        end
        
        function h = Hipervolume(nsga, pareto) 
            % numero de pontos
            n = size(pareto,1);
            
            % ponto nadir afastado em 1.1%
            nadir = 1.1*nsga.Nadir;
            
            % ponto utópico
            AStar = nsga.Utopico;
            
            % ordena as soluções
            [~,id] = sort(pareto(:,1));
            pareto = pareto(id,:);
            
            % cálculo do volume utópico
            hvStar = (nadir(1) - AStar(1)) * (nadir(2) - AStar(2));
            
            % cálculo dos volumes de cada solução
            hv = (nadir(1) - pareto(1,1)) * (nadir(2) - pareto(1,2));
            for i=2:n
                hv = hv + (nadir(1) - pareto(i,1)) * (pareto(i-1,2) - pareto(i,2));
            end
            
            h = hv/hvStar;
        end
        
        function d = GetDistance(~,x1,x2)
            d = abs(x1(1) - x2(1)) + abs(x1(2) - x2(2));
        end
    end
end