minVolumes = ones(numel(volumes),1);
meanVolumes = ones(numel(volumes),1);

for i=1:numel(volumes)
    minVolumes(i) = min(min(volumes{i}./repmat(V(:,2),1,T)));
    meanVolumes(i) = mean(min(volumes{i}./repmat(V(:,2),1,T)));
end

minVolumes
meanVolumes