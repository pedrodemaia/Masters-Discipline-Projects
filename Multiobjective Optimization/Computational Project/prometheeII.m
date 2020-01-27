function [numSobreclassificacoes, ordemPrioridade] = prometheeII(pareto)

    alternativas = pareto;
    tempo = alternativas(:,1);
    distancia = alternativas(:,2);
    velocidade = alternativas(:,2) ./ alternativas(:,1);
    
    alternativas = [tempo distancia velocidade;];
    
    dominadas = domina(alternativas);
    
    %eliminando itens dominados
    for i=size(tempo,1):-1:1
        for j=length(dominadas):-1:1
            if(i==dominadas(j))
                tempo(i,:) = [];
                distancia(i,:) = [];
                velocidade(i,:) = [];
                break;
            end
        end
    end
    
    % pesos definidos pelo AHP
    pesos = [1, 2, 5;1/3, 1, 4; 1/5, 1/3, 1];
    %normalizando os pesos
    pesos = pesos/norm(pesos);
    
    indexAlternativa = 1:1:(size(velocidade,1));
    
    %% Cria??o da Matriz de Prefer?ncia
    % Inicializa??o da compara??o par-a-par e montagem da matriz de
    % prefer?ncia
    matrixPreferencia = [];
    for i=1:length(indexAlternativa)
        for j=1:length(indexAlternativa)
            tempoAux = [];
            distanciaAux = [];
            velocidadeAux = [];
            if(i==j) 
                continue;
            else
                if(tempo(i)>tempo(j))
                    tempoAux = tempo(i)-tempo(j);
                else
                    tempoAux = 0;
                end
                if(distancia(i)>distancia(j))
                    distanciaAux = distancia(i)-distancia(j);
                else
                    distanciaAux = 0;
                end
                if(velocidade(i)>velocidade(j))
                    velocidadeAux = velocidade(i)-velocidade(j);
                else 
                    velocidadeAux = 0;
                end
            end
            matrixPreferencia = [matrixPreferencia; tempoAux distanciaAux velocidadeAux];
        end
    end
    
    %% Utiliza??o do Crit?rio de Prefer?ncia Linear
    p = 150;   
    for i=1:size(matrixPreferencia,1)
        for j=1:size(matrixPreferencia,2)
            if (matrixPreferencia(i,j) <= 0)
                matrixPreferencia(i,j) = 0;
            elseif (matrixPreferencia(i,j) > 0 && matrixPreferencia(i,j) <= p)
                matrixPreferencia(i,j) = matrixPreferencia(i,j)/p;
            elseif matrixPreferencia(i,j) > p
                matrixPreferencia(i,j) = 1;
            end
        end
    end
    
    %% Calcular ?ndice de prefer?ncia
    indicePreferencia = zeros(size(matrixPreferencia,2),1);
    for i=1:size(matrixPreferencia,1)
        indicePreferencia(i,1) = (matrixPreferencia(i,1) * sum(pesos(1,:))/sum(sum(pesos)) + ...
                                  matrixPreferencia(i,2) * sum(pesos(2,:))/sum(sum(pesos)) + ...
                                  matrixPreferencia(i,3) * sum(pesos(3,:))/sum(sum(pesos)));
    end
    
    %% Calcular Fluxo Positivo e Fluxo Negativo
    

    auxFator = length(indicePreferencia)/length(indexAlternativa);

    % Fluxo Negativo
    fluxoNegativo = [];
    for i=1:length(indexAlternativa)
        auxFluxo = 0;
        for j=i:auxFator:length(indicePreferencia)
            auxFluxo = auxFluxo + indicePreferencia(j);
        end
        fluxoNegativo= [fluxoNegativo; auxFluxo];
    end
    
    %Fluxo Positivo
	fluxoPositivo = [];  
    aux = 1;
	for i=1:length(indexAlternativa)
        auxFluxo = 0;
        for j=aux:1:(auxFator*i)
            auxFluxo = auxFluxo + indicePreferencia(j);
            aux = j;
        end
        fluxoPositivo= [fluxoPositivo; auxFluxo];
	end
    
    %% Prom?th?e II - Calculo do Fluxo de Supera??o
    fluxoSuperacao = [];
    for i=1:length(indexAlternativa)
        fluxoSuperacao = [fluxoSuperacao; fluxoPositivo(i)-fluxoNegativo(i)];
    end
    
    
    %retorna o n?mero de sobreclassifica??es e a ordem de prioridade de
    %cada uma.
    [numSobreclassificacoes, ordemPrioridade] = sort(fluxoSuperacao,'descend');
end

