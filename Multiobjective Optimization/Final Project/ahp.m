%% Teoria da Decis?o - M?todos de aux?lio a tomada de decis?o - M?todo AHP
% Author: Filipe Barreto Diniz
% Trabalho de Computacional 2

function [vCri] = ahp(Ce)
    
    alternativas = Ce;
        
    % Define a Tabela Criterios
    criterios = [1, 3;1/3, 1];
    cr = length(criterios);
    
    % Definindo a tabela de prioridade dos Criterios
    N=zeros(cr,1);
    sumPref = sum(criterios, 1);
    for i = 1 : cr
       N(:, i) = criterios(:, i)/sumPref(i);
    end
    
    % Normalizar a tabela equivalente aos criterios
    vCri = mean(N, 2);

end


%% Fun??o para calcular o coenficiente de consistencias
function [qc] = coefConsistencias(tabelas)
    n = size(tabelas,2);
    
    % De acordo com o valor da ordem da tabela, o ICA ter? um valor fixo
    % definido por uma tabela que consta nos slides disponibilizados pelo
    % professor
    
    ICA = 1.49;
    
    % Calculo do QC
    lamb=max(eig(tabelas));
    IC=(lamb-n)/(n-1);
    qc=IC/ICA;

end