function oimg=demosaicHA(img,bayerpattern)

switch lower(bayerpattern)
    case 'rggb'
        oimg = CFAIHamiltonAdams(img, 2);
    case 'grbg'
        oimg = CFAIHamiltonAdams(img, 1);
    case 'bggr'
        oimg = CFAIHamiltonAdams(img, 2);
        oimg = oimg(:, :, [3 2 1]);
    case 'gbrg'
        oimg = CFAIHamiltonAdams(img,1);
        oimg = oimg(:,:,[3 2 1]);
    otherwise
        error('Unknown Bayer Pattern!');
        
end


function [out, out_var] = CFAIHamiltonAdams(in, CFA_phaseshift)

if nargin<2, CFA_phaseshift = 1; end

in = double(in);

switch CFA_phaseshift
    case 1
        tmpin = zeros([size(in,1) size(in,2)+2 size(in,3)]);
        tmpin(:, 2:end-1, :) = in;
        in = tmpin;
    case 2
end

truein = in;

out = zeros(size(in));

[N, M, ch] = size(in);
if ch==3
    inR = in(:,:,1); inG = in(:,:,2); inB = in(:,:,3);
    outR  = inR(1:2:end, 1:2:end);
    outB  = inB(2:2:end, 2:2:end);
    outG1 = inG(1:2:end, 2:2:end);
    outG2 = inG(2:2:end, 1:2:end);
end

if ch==1
    outR  = in(1:2:end, 1:2:end);
    outB  = in(2:2:end, 2:2:end);
    outG1 = in(1:2:end, 2:2:end);
    outG2 = in(2:2:end, 1:2:end);
end


% A. Interpolation of missing G values
% at R positions
hRgrad = abs(convn(outR, [-1  2  -1], 'same')) + circshift(abs(convn(outG1, [1 -1], 'same')), [0 1]);
vRgrad = abs(convn(outR, [-1; 2; -1], 'same')) + circshift(abs(convn(outG2, [1;-1], 'same')), [1 0]);

hGcR = circshift(convn(outG1, [1  1]./2, 'same'), [0 1]) + convn(outR, [-1  2  -1]./4, 'same');
vGcR = circshift(convn(outG2, [1; 1]./2, 'same'), [1 0]) + convn(outR, [-1; 2; -1]./4, 'same');
GcR = hGcR.*(hRgrad<vRgrad) + vGcR.*(hRgrad>vRgrad) + (hGcR./2 + vGcR./2).*(hRgrad==vRgrad);
% GcR = (hGcR./2 + vGcR./2);

% at B positions
hBgrad = abs(convn(outB, [-1  2  -1], 'same')) + circshift(abs(convn(outG2, [1  -1], 'same')), [0 0]);
vBgrad = abs(convn(outB, [-1; 2; -1], 'same')) + circshift(abs(convn(outG1, [1; -1], 'same')), [0 0]);

hGcB = circshift(convn(outG2, [1  1]./2, 'same'), [0 0]) + convn(outB, [-1  2  -1]./4, 'same');
vGcB = circshift(convn(outG1, [1; 1]./2, 'same'), [0 0]) + convn(outB, [-1; 2; -1]./4, 'same');
GcB = hGcB.*(hBgrad<vBgrad) + vGcB.*(hBgrad>vBgrad) + (hGcB./2 + vGcB./2).*(hBgrad==vBgrad);
% GcB = (hGcB./2 + vGcB./2);

finG = zeros(N,M);
finG(1:2:end,1:2:end) = GcR;
finG(1:2:end,2:2:end) = outG1;
finG(2:2:end,1:2:end) = outG2;
finG(2:2:end,2:2:end) = GcB;

% B. Interpolation of missing R values
RcG1 = convn(outR, [1  1]./2, 'same') + outG1 - convn(GcR, [1  1]./2, 'same');
RcG2 = convn(outR, [1; 1]./2, 'same') + outG2 - convn(GcR, [1; 1]./2, 'same');

hRgrad = abs(2.*GcB - convn(GcR, [0 1; 1 0], 'same')) + abs(convn(outR, [0 1; -1 0], 'same'));
vRgrad = abs(2.*GcB - convn(GcR, [1 0; 0 1], 'same')) + abs(convn(outR, [1 0; 0 -1], 'same'));

hR = convn(outR, [0 1; 1 0]./2, 'same') + GcB - convn(GcR, [0 1; 1 0]./2, 'same');
vR = convn(outR, [1 0; 0 1]./2, 'same') + GcB - convn(GcR, [1 0; 0 1]./2, 'same');
RcB = hR.*(hRgrad<vRgrad) + vR.*(hRgrad>vRgrad) + (hR./2 + vR./2).*(hRgrad==vRgrad);
% RcB = hRgrad;%.*(hRgrad<vRgrad) + vR.*(hRgrad>vRgrad) + (hR./2 + vR./2).*(hRgrad==vRgrad);

finR = zeros(N,M);
finR(1:2:end,1:2:end) = outR;
finR(1:2:end,2:2:end) = RcG1;
finR(2:2:end,1:2:end) = RcG2;
finR(2:2:end,2:2:end) = RcB;

% C. Interpolation of missing B values
BcG1 = convn(outB, [1; 1]./2, 'same') + circshift(outG1, [-1 0]) - convn(GcB, [1; 1]./2, 'same');
BcG2 = convn(outB, [1  1]./2, 'same') + circshift(outG2, [0 -1]) - convn(GcB, [1  1]./2, 'same');

if nargin>=5
    BcG1_var = convn(outB_var, ([1; 1]./2).^2, 'same') +  circshift(outG1_var, [-1 0]) + convn(GcB_var, ([1; 1]./2).^2, 'same');
    BcG2_var = convn(outB_var, ([1  1]./2).^2, 'same') +  circshift(outG2_var, [0 -1]) + convn(GcB_var, ([1  1]./2).^2, 'same');
end

hBgrad = abs(2.*circshift(GcR, [-1 -1]) - convn(GcB, [0 1; 1 0], 'same')) + abs(convn(outB, [0 1; -1 0], 'same'));
vBgrad = abs(2.*circshift(GcR, [-1 -1]) - convn(GcB, [1 0; 0 1], 'same')) + abs(convn(outB, [1 0; 0 -1], 'same'));

hB = convn(outB, [0 1; 1 0]./2, 'same') + circshift(GcR, [-1 -1]) - convn(GcB, [0 1; 1 0]./2, 'same');
vB = convn(outB, [1 0; 0 1]./2, 'same') + circshift(GcR, [-1 -1]) - convn(GcB, [1 0; 0 1]./2, 'same');
BcR = hB.*(hBgrad<vBgrad) + vB.*(hBgrad>vBgrad) + (hB./2 + vB./2).*(hBgrad==vBgrad);

if nargin>=5
    hB_var = convn(outB_var, ([0 1; 1 0]./2).^2, 'same') + circshift(GcR_var, [-1 -1]) + convn(GcB_var, ([0 1; 1 0]./2).^2, 'same');
    vB_var = convn(outB_var, ([1 0; 0 1]./2).^2, 'same') + circshift(GcR_var, [-1 -1]) + convn(GcB_var, ([1 0; 0 1]./2).^2, 'same');
    BcR_var = hB_var.*(hBgrad<vBgrad) + vB_var.*(hBgrad>vBgrad) + (hB_var./4 + vB_var./4).*(hBgrad==vBgrad);
end

finB = zeros(N,M);
finB(1:2:end,1:2:end) = circshift(BcR, [1 1]);
finB(1:2:end,2:2:end) = circshift(BcG1,[1 0]);
finB(2:2:end,1:2:end) = circshift(BcG2,[0 1]);
finB(2:2:end,2:2:end) = outB;

if nargin>=5
    finB_var = zeros(N,M);
    finB_var(1:2:end,1:2:end) = circshift(BcR_var, [1 1]);
    finB_var(1:2:end,2:2:end) = circshift(BcG1_var,[1 0]);
    finB_var(2:2:end,1:2:end) = circshift(BcG2_var,[0 1]);
    finB_var(2:2:end,2:2:end) = outB_var;
end

% Fusing
out(:,:,1) = finR;
out(:,:,2) = finG;
out(:,:,3) = finB;

if nargin>=5
    out_var(:,:,1) = sqrt(finR_var);
    out_var(:,:,2) = sqrt(finG_var);
    out_var(:,:,3) = sqrt(finB_var);
end

switch CFA_phaseshift
    case 1
        out = out(:, 2:end-1, :);
    case 2
end
