function [numSobreclassificacoes, ordemPrioridade] = prometheeII()

    load resultsFinais.mat
    
    alternativas = Ce';
    custo = alternativas(:,1);
    nivel = alternativas(:,2);
    
    %Calcular os pesos de acordo com o AHP
    peso = ahp(alternativas);
    pesos = [peso(1);peso(2)];
    
    dominadas = domina(alternativas);
    
    %eliminando itens dominados
    for i=size(custo,1):-1:1
        for j=length(dominadas):-1:1
            if(i==dominadas(j))
                custo(i,:) = [];
                nivel(i,:) = [];
                break;
            end
        end
    end
    
    % alternativas = [custo nivel;];
    
    indexAlternativa = 1:1:(size(nivel,1));
    
    %% Cria??o da Matriz de Prefer?ncia
    % Inicializa??o da compara??o par-a-par e montagem da matriz de
    % prefer?ncia
    matrixPreferencia = [];
    for i=1:length(indexAlternativa)
        for j=1:length(indexAlternativa)
            custoAux = [];
            nivelAux = [];
            if(i==j) 
                continue;
            else
                if(custo(i)>custo(j))
                    custoAux = custo(i)-custo(j);
                else
                    custoAux = 0;
                end
                if(nivel(i)>nivel(j))
                    nivelAux = nivel(i)-nivel(j);
                else
                    nivelAux = 0;
                end
            end
            matrixPreferencia = [matrixPreferencia; custoAux nivelAux];
        end
    end
    
    %% Utilizando do Crit?rio de Prefer?ncia Linear
    p = 4e10;   
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
        indicePreferencia(i,1) = (matrixPreferencia(i,1) * pesos(1,:) + ...
                                  matrixPreferencia(i,2) * pesos(2,:));
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
    
    %% Promethee II - Calculo do Fluxo de Supera??o
    fluxoSuperacao = [];
    for i=1:length(indexAlternativa)
        fluxoSuperacao = [fluxoSuperacao; fluxoPositivo(i)-fluxoNegativo(i)];
    end
    
    
    %retorna o n?mero de sobreclassifica??es e a ordem de prioridade de
    %cada uma.
    [numSobreclassificacoes, ordemPrioridade] = sort(fluxoSuperacao,'descend');
end

