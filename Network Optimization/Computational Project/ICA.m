classdef ICA
    properties
        TSP % problema TSP
        Empire % lista de imp�rios do modelo (1o elemento � a metr�pole)
        Time % lista de tempos totais de cada pa�s
        N % n�mero de pa�ses do modelo
        rho % chance da col�nia sofrer revolu��o
        permute % m�ximo n�mero de cidades que podem ser permutadas
    end
    
    methods
        function ica = ICA(tsp,n,imp)
            % tsp: uma inst�ncia do caixeiro viajante
            % n: n�mero de indiv�duos
            % imp: n�mero de imp�rios
            
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
                % altera o tour de cada col�nia de cada imp�rio
                for e=1:length(ica.Empire)
                    metropole = ica.Empire{e}(1,:);
                    colonies = ica.Empire{e}(2:end,:);
                    tempos = ica.Time{e};
                    
                    for c=1:size(colonies,1)
                        % realiza as permuta��es nas col�nias
                        colony = colonies(c,:);
                        id = sort(randperm(ica.TSP.N,randi(ica.permute)));
                        cities = colony(id);
                        [~,metroOrder] = ismember(cities,metropole);
                        [~,pos] = sort(metroOrder);
                        colony(id) = cities(pos);
                        
                        if ica.TSP.IndividuoValido(colony)
                            tempo = ica.TSP.TempoTotal(colony);
                            
                            % realiza a revolu��o da col�nia
                            if rand < ica.rho
                                [auxColony,auxTempo] = ica.TSP.TwoOpt(colony,ica.TSP.N);
                                if auxTempo < tempo
                                    colony = auxColony;
                                    tempo = auxTempo;
                                end
                            end
                        
                            % atualiza a col�nia permutada e revolucionada
                            colonies(c,:) = colony;
                            tempos(c+1) = tempo;
                        end
                    end
                    
                    % checa se alguma col�nia ficou melhor que a metr�pole
                    [~,bestTime] = min(tempos);
                    if bestTime > 1
                        % atualiza a melhor solu��o
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
                
                % transfere a col�nia mais fraca do imp�rio mais fraco para
                % o imp�rio mais forte
                [~,weakest] = max(empirePower);
                [~,strongest] = min(empirePower);
                
                [worstTime,worstColony] = max(ica.Time{weakest});
                colony = ica.Empire{weakest}(worstColony,:);
                
                ica.Empire{strongest}(end+1,:) = colony;
                ica.Time{strongest}(end+1) = worstTime;
                
                ica.Empire{weakest}(worstColony,:) = [];
                ica.Time{weakest}(worstColony) = [];
                
                % elimina imp�rio mais fraco caso perca todas as col�nias
                if size(ica.Empire{weakest},1) == 1
                    ica.Empire(weakest) = [];
                    ica.Time(weakest) = [];
                end
            end
        end
    end
end