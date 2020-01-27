function dTotal = domina(alternativa)
    
    dTotal = [];
    for i=1:size(alternativa,1)
        for j=1:size(alternativa,1)   
            e = 0.0;
            if i==j
                continue
            end
            t1 = (alternativa(i,1));
            t2 = (alternativa(j,1));
            
            d1 = (alternativa(i,2));
            d2 = (alternativa(j,2));
            
            v1 = (alternativa(i,3));
            v2 = (alternativa(j,3));
            d = d1 - e >= d2 && t1 - e >= t2 && v1 - e <= v2;
            if d == 1
                dTotal = [dTotal; i];
                break;
            end
        end
    end
end