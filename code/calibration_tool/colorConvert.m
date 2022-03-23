function oimg=colorConvert(img,matrix)

[r,c,d]=size(img);
img=double(img);
[do,x]=size(matrix);
oimg=reshape(reshape(img,[],d)*matrix',[r,c,do]);
