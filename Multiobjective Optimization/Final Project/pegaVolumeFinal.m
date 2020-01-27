volumeFinal = zeros(U,numel(volumes));
for i=1:numel(volumes)
    volumeFinal(:,i) = volumes{i}(:,end);
end
volumeFinal - V(:,2)