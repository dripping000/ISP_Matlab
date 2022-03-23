function out=demosaicNN(img,bayerpattern)

[r,c,d]=size(img);
if d~=1
    error('Wrong Image format!');
end
%convert to GRBG or GBRG for total processing
if strcmpi(bayerpattern,'rggb')||strcmpi(bayerpattern,'bggr')
    tempImg=zeros(r+2,c);
    tempImg(2:end-1,:)=img;
    tempImg(1,:)=tempImg(3,:);
    tempImg(end,:)=tempImg(end-2,:);
else
    tempImg=img;
end    
    
G=tempImg;
G(2:2:end,1:2:end)=G(1:2:end,1:2:end);
G(1:2:end,2:2:end)=G(2:2:end,2:2:end);

R=tempImg;
R(1:2:end,1:2:end)=R(1:2:end,2:2:end);
R(2:2:end,1:2:end)=R(1:2:end,2:2:end);
R(2:2:end,2:2:end)=R(1:2:end,2:2:end);

B=tempImg;
B(1:2:end,1:2:end)=B(2:2:end,1:2:end);
B(1:2:end,2:2:end)=B(2:2:end,1:2:end);
B(2:2:end,2:2:end)=B(2:2:end,1:2:end);

switch lower(bayerpattern)
    case 'rggb'
        out=cat(3,B,G,R);
        out=out(2:end-1,:,:);
    case 'bggr'
        out=cat(3,R,G,B);
        out=out(2:end-1,:,:);
    case 'grbg'
        out=cat(3,R,G,B);
    case 'gbrg'
        out=cat(3,B,G,R);
end



