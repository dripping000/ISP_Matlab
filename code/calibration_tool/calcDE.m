function de=calcDE(Lab1,Lab2,spec)
%lab1 and lab2 are nx3 lab2 can be nx1
if nargin<3, spec='de76';end
n=size(Lab1);
if numel(Lab2)==3,Lab2=repmat(Lab2(:)',[n,1]);end
switch lower(spec)
    case 'de76'
        de=deltaEab(Lab1',Lab2');
    case 'de94'
        de=deltaE94(Lab1',Lab2');
    case 'de00'
        de=deltaE00(Lab1',Lab2');
    case 'ab'
        de=deltaAB(Lab1',Lab2');
    otherwise
        error('Unknown Spec! Must be de76 de94 de00');
end


function  deltaEab=deltaEab(Labb,Lab) 
deltaL=Labb(1,:)-Lab(1,:);
deltaa=Labb(2,:)-Lab(2,:);
deltab=Labb(3,:)-Lab(3,:);
deltaEab=(deltaL.^2+deltaa.^2+deltab.^2).^(1/2);


function  deltaEab=deltaAB(Labb,Lab) 
deltaa=Labb(2,:)-Lab(2,:);
deltab=Labb(3,:)-Lab(3,:);
deltaEab=(deltaa.^2+deltab.^2).^(1/2);




function [DE94] = deltaE94(LabBat, LabStd, varargin)

         delLab=LabBat-LabStd;
         
         Cb=(LabBat(2,:).^2+LabBat(3,:).^2).^(1/2);
         Cs=(LabStd(2,:).^2+LabStd(3,:).^2).^(1/2); 
         
         DEC=Cb-Cs;
         deltaEab=(delLab(1,:).^2+delLab(2,:).^2+delLab(3,:).^2).^(1/2);
         DEH=(deltaEab.^2-delLab(1,:).^2-DEC.^2).^(1/2);
         
         if  any(strcmp(varargin,'geometric mean'))
             Cab=(Cb.*Cs).^(1/2);
       
         else
             Cab=Cs;
         end
        
         SL=1;
         SC=1+0.045*Cab;
         SH=1+0.015*Cab;
         kL=1;
         kC=1;
         kH=1;
         DE94=((delLab(1,:)./(kL*SL)).^2+(DEC./(kC*SC)).^2+(DEH./(kH*SH)).^2).^(1/2);




function   De00=deltaE00(Lab1, Lab2)

%CIELAB Chroma
C1 = sqrt(Lab1(2,:).^2+Lab1(3,:).^2);
C2 = sqrt(Lab2(2,:).^2+Lab2(3,:).^2);

%Lab Prime
mC = (C1+C2)./2;
G=0.5*(1-sqrt((mC.^7)./((mC.^7)+(25.^7))));
LabP1 = [Lab1(1,:) ; Lab1(2,:).*(1+G) ; Lab1(3,:)];
LabP2 = [Lab2(1,:) ; Lab2(2,:).*(1+G) ; Lab2(3,:)];

%Chroma
CP1 = sqrt(LabP1(2,:).^2+LabP1(3,:).^2);
CP2 = sqrt(LabP2(2,:).^2+LabP2(3,:).^2);

%Hue Angle
hP1t = atan2Deg(LabP1(3,:),LabP1(2,:));
hP2t = atan2Deg(LabP2(3,:),LabP2(2,:));

%Add in 360 to the smaller hue angle if absolute value of difference is > 180
hP1 = hP1t + ((hP1t<hP2t)&(abs(hP1t-hP2t)>180)).*360;
hP2 = hP2t + ((hP1t>hP2t)&(abs(hP1t-hP2t)>180)).*360;

%Delta Values
DLP = LabP1(1,:) - LabP2(1,:);
DCP = CP1 - CP2;
DhP = hP1 - hP2;
DHP = 2*(CP1.*CP2).^(1/2).*sinDeg(DhP./2);

%Arithmetic mean of LCh' values
mLP = (LabP1(1,:)+LabP2(1,:))./2;
mCP = (CP1+CP2)./2;
mhP = (hP1+hP2)./2;

%Weighting Functions
SL = 1+(0.015.*(mLP-50).^2)./sqrt(20+(mLP-50).^2);
SC = 1+0.045.*mCP;
T = 1-0.17.*cosDeg(mhP-30)+0.24.*cosDeg(2.*mhP)+0.32.*cosDeg(3.*mhP+6)-0.2.*cosDeg(4.*mhP-63);
SH = 1+0.015.*mCP.*T;

%Rotation function
RC = 2.*sqrt((mCP.^7)./((mCP.^7)+25.^7));
DTheta = 30.*exp(-((mhP-275)./25).^2);
RT = -sinDeg(2.*DTheta).*RC;

%Parametric factors
kL = 1;
kC = 1;
kH = 1;

De00 = ((DLP./kL./SL).^2+(DCP./kC./SC).^2+(DHP./kH./SH).^2+(RT.*(DCP./kC./SC).*(DHP./kH./SH))).^(1/2);

% ------------- define a few convenient subfunctions -------------
function out = atan2Deg(inY,inX)
out = atan2(inY,inX).*180./pi;
out = out+(out<0).*360;

function out = sinDeg(in)
out = sin(in.*pi./180);

function out = cosDeg(in)
out = cos(in.*pi./180);