function lab=lRGB2LAB(RGB)
% This script converts linear XYZ to L*a*b space

%converts RGB to XYZ
XYZ = lRGB2XYZ(RGB);

lab=xyz2lab(XYZ,'WhitePoint','d65');
