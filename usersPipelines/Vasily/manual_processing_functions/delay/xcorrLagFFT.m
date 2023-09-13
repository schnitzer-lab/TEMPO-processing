function [lag, r, lags, xc] = xcorrLagFFT(x1, x2, upsample, maxlag, positive)
    
    if(nargin < 4)
        maxlag = Inf;
    end
    
    if(nargin < 5)
        positive = false;
    end
    % based on interpft code
    % guaranteed that upsampling works nicely and coinsides with the not
    % umsampled version on the borders
    z1 = fft(x1);
    z2 = fft(x2);


    dshift = floor(size(z1, 1)/2);
    % s = fft(fftshift(ifft(z1.*conj(z2))));
    s = -z1.*conj(z2).*exp(-1.i*2*pi*(1:size(z1, 1))'*dshift/size(z1, 1));

    [m,n] = size(s);

    ny = m*upsample;
    nyqst = ceil((m+1)/2);
    b = [s(1:nyqst,:) ; zeros(ny-m,n) ; s(nyqst+1:m,:)];
    if rem(m,2) == 0
        b(nyqst,:) = b(nyqst,:)/2;
        b(nyqst+ny-m,:) = b(nyqst,:);
    end

    xc = ifft(b,[],1);
    if isreal(x2) && isreal(x1), xc = real(xc); end

    xc = xc * upsample / (norm(x1)*norm(x2));
    xc = xc(1:(end-round(upsample)+1));

    lags = linspace(1,length(x1), length(xc));
    lags = lags - floor((2+length(x1))/2);

    xc = xc(abs(lags) < maxlag);
    if(~positive)
        [~, ind0] = max(abs(xc));
    else
        [~, ind0] = max(xc);
    end
    r = xc(ind0);
    
    lags_less = lags(abs(lags) < maxlag);
    lag = lags_less(ind0);
end