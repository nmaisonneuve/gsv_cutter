function oim=iminterpnn(iim, U, V);
%% Nearest neighbour interpolation.
    U=int32(round(U)); V=int32(round(V));
    [h0, w0, ~] = size(iim);
    [h w] = size(U);
    npix = h * w;
    npix0 = h0 * w0;
    oim = zeros(h, w, 3, 'uint8');
    I = find(0<V & V<=h0 & 0<U & U<=w0);
    J = (U(I) - 1) * h0 + V(I);
    I = [I; I + npix; I + 2 * npix];
    J = [J; J + npix0; J + 2 * npix0];
    oim(I) = iim(J);
end