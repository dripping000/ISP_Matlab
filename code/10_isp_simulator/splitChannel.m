function [CH , color] = splitChannel(img, bayerPattern)


[height, width] = size(img);

CH = []; 

CH(:,:,1) = img(1:2:height,1:2:width); %upper left;
CH(:,:,2) = img(1:2:height,2:2:width); %upper right
CH(:,:,3) = img(2:2:height,1:2:width); %lower left
CH(:,:,4) = img(2:2:height,2:2:width); %lower right

bayerPattern = lower(bayerPattern);
if strcmpi(bayerPattern, 'bggr')
    color = ['Blue'; 'Gb  '; 'Gr  '; 'Red '];
elseif strcmpi(bayerPattern, 'rggb')
    color = ['Red '; 'Gr  '; 'Gb  '; 'Blue'];
elseif strcmpi(bayerPattern, 'gbrg')
    color = ['Gb  '; 'Blue'; 'Red '; 'Gr  '];
elseif strcmpi(bayerPattern, 'grbg')
    color = ['Gr  '; 'Red '; 'Blue'; 'Gb  '];
else
    g = msgbox('Bayer Pattern Error');
    uiwait(g);
end