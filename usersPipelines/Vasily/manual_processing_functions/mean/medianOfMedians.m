% matlab's median overhear is 3x, prohibitive for large movies
function m =  medianOfMedians(M, ns)
    sample_size = floor(size(M,3)/ns);
    inx = datasample(1:size(M,3), sample_size*ns,'Replace',false);
    medians = nan([size(M,[1,2]), ns]);
    for i = 1:ns
%         disp(i)
        medians(:,:,i) =...
            median(M(:,:, inx((1+(i-1)*sample_size):(i*sample_size))), 3,'omitnan');
    end
    m = median(medians, 3);  
end