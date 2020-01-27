classdef ICA
    properties
        TSP % problema TSP
        Empire % lista de impérios do modelo (1o elemento é a metrópole)
        Time % lista de tempos totais de cada país
        N % número de países do modelo
        rho % chance da colônia sofrer revolução
        permute % máximo número de cidades que podem ser permutadas
    end
    
    methods
        function ica = ICA(tsp,n,imp)
            % tsp: uma instância do caixeiro viajante
            % n: número de indivíduos
            % imp: número de impérios
            
            ica.rho = 0.2;
            ica.permute = tsp.N-2;
            ica.TSP = tsp;
            ica.N = n;
            
            pais = zeros(n,tsp.N);
            tempo = zeros(n,1);
            for i=1:n
                pais(i,:) = tsp.CriaIndividuo;
                tempo(i) = tsp.TempoTotal(pais(i,:));
            end
            [~,index] = sort(tempo);
            metropole = sort(index(1:imp));
            
            empire = mat2cell(pais(metropole,:),ones(imp,1),size(pais,2))';
            pais(metropole,:) = [];
            times = mat2cell(tempo(metropole),ones(imp,1),1)';
            tempo(metropole) = [];
            
            for i=1:imp
                colonies = randperm(size(pais,1),(n-imp)/imp);
                empire{i} = [empire{i}; pais(colonies,:)];
                times{i} = [times{i}; tempo(colonies)];
                pais(colonies,:) = [];
                tempo(colonies) = [];
            end
            
            ica.Empire = empire;
            ica.Time = times;
        end
        
        function [xStar,fxStar] = Optimize(ica)
            metropoleTime = min(cell2mat(ica.Time));
            [fxStar,id] = min(metropoleTime);
            xStar = ica.Empire{id}(1,:);
            
            iter = 0;
            noImprove = 0;
            while noImprove < 5
                iter = iter + 1
                noImprove = noImprove + 1
                empirePower = zeros(length(ica.Empire),1);
                % altera o tour de cada colônia de cada império
                for e=1:length(ica.Empire)
                    metropole = ica.Empire{e}(1,:);
                    colonies = ica.Empire{e}(2:end,:);
                    tempos = ica.Time{e};
                    
                    for c=1:size(colonies,1)
                        % realiza as permutações nas colônias
                        colony = colonies(c,:);
                        id = sort(randperm(ica.TSP.N,randi(ica.permute)));
                        cities = colony(id);
                        [~,metroOrder] = ismember(cities,metropole);
                        [~,pos] = sort(metroOrder);
                        colony(id) = cities(pos);
                        
                        if ica.TSP.IndividuoValido(colony)
                            tempo = ica.TSP.TempoTotal(colony);
                            
                            % realiza a revolução da colônia
                            if rand < ica.rho
                                [auxColony,auxTempo] = ica.TSP.TwoOpt(colony,ica.TSP.N);
                                if auxTempo < tempo
                                    colony = auxColony;
                                    tempo = auxTempo;
                                end
                            end
                        
                            % atualiza a colônia permutada e revolucionada
                            colonies(c,:) = colony;
                            tempos(c+1) = tempo;
                        end
                    end
                    
                    % checa se alguma colônia ficou melhor que a metrópole
                    [~,bestTime] = min(tempos);
                    if bestTime > 1
                        % atualiza a melhor solução
                        if fxStar > tempos(bestTime)
                            xStar = colonies(bestTime-1,:);
                            fxStar = tempos(bestTime);
                            noImprove = 0;
                        end
                        
                        ica.Empire{e}(1,:) = colonies(bestTime-1,:);
                        colonies(bestTime-1,:) = metropole;
                        
                        auxTime = tempos(1);
                        tempos(1) = tempos(bestTime);
                        tempos(bestTime) = auxTime;
                    end
                    
                    ica.Empire{e}(2:end,:) = colonies;
                    ica.Time{e} = tempos;
                    
                    empirePower(e) = tempos(1) + 0.5*mean(tempos(2:end));
                end
                
                % transfere a colônia mais fraca do império mais fraco para
                % o império mais forte
                [~,weakest] = max(empirePower);
                [~,strongest] = min(empirePower);
                
                [worstTime,worstColony] = max(ica.Time{weakest});
                colony = ica.Empire{weakest}(worstColony,:);
                
                ica.Empire{strongest}(end+1,:) = colony;
                ica.Time{strongest}(end+1) = worstTime;
                
                ica.Empire{weakest}(worstColony,:) = [];
                ica.Time{weakest}(worstColony) = [];
                
                % elimina império mais fraco caso perca todas as colônias
                if size(ica.Empire{weakest},1) == 1
                    ica.Empire(weakest) = [];
                    ica.Time(weakest) = [];
                end
            end
        end
    end
end