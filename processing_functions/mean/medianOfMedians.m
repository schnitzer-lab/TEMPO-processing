% matlab's median overhead is 3x, prohibitive for large movies
function m =  medianOfMedians(M, ns)

    nmedians = ceil(size(M,3)/ns);
    medians = nan([size(M,[1,2]), nmedians]);
    for i_m = 1:nmedians
        range = [(1+(i_m-1)*ns), min(i_m*ns, size(M,3))];
        medians(:,:,i_m) = median(M(:,:, range(1):range(2)), 3,'omitnan');
    end

    m = median(medians, 3); 
end