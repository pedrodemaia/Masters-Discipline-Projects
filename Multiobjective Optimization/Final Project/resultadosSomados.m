[~,ordem] = sort(Ce(1,:));
n = numel(volumes);

Ce = Ce(:,ordem);

volumes = volumes(ordem);
engolimentos = engolimentos(ordem);
vertimentos = vertimentos(ordem);
geracoes = geracoes(ordem);
geracaoComp = geracaoComp(ordem);

volumeTotal = zeros(n,1);
engolimentoTotal = zeros(n,1);
vertimentoTotal = zeros(n,1);
geracaoTotal = zeros(n,1);
geracaoCompTotal = zeros(n,1);

for i=1:n
    volumeTotal(i) = sum(sum(volumes{i}));
    engolimentoTotal(i) = sum(sum(engolimentos{i}));
    vertimentoTotal(i) = sum(sum(vertimentos{i}));
    geracaoTotal(i) = sum(sum(geracoes{i}));
    geracaoCompTotal(i) = sum(geracaoComp{i});
end

resultados = [volumeTotal engolimentoTotal vertimentoTotal geracaoTotal geracaoCompTotal]
