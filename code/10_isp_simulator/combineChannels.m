function combinedImg = combineChannels2( channel ,bayerpattern )

[height,width,d] = size(channel);
height = height*2;
width = width*2;
if d == 1
    combinedImg = channel;
elseif d ~= 4
    errordlg('There should be 4 channels for combination!');
else
    combinedImg = [];
    if nargin < 2
        combinedImg(1:2:height,1:2:width) = channel(:,:,1);
        combinedImg(1:2:height,2:2:width) = channel(:,:,2);
        combinedImg(2:2:height,1:2:width) = channel(:,:,3);
        combinedImg(2:2:height,2:2:width) = channel(:,:,4);
    else
        switch lower(bayerpattern)
            case 'rggb'
                combinedImg(1:2:height,1:2:width) = channel(:,:,1); % R
                combinedImg(1:2:height,2:2:width) = channel(:,:,2); % Gr
                combinedImg(2:2:height,1:2:width) = channel(:,:,3); % Gb
                combinedImg(2:2:height,2:2:width) = channel(:,:,4); % B
            case 'grbg'
                combinedImg(1:2:height,1:2:width) = channel(:,:,2);
                combinedImg(1:2:height,2:2:width) = channel(:,:,1);
                combinedImg(2:2:height,1:2:width) = channel(:,:,4);
                combinedImg(2:2:height,2:2:width) = channel(:,:,3);
            case 'gbrg'
                combinedImg(1:2:height,1:2:width) = channel(:,:,3);
                combinedImg(1:2:height,2:2:width) = channel(:,:,4);
                combinedImg(2:2:height,1:2:width) = channel(:,:,1);
                combinedImg(2:2:height,2:2:width) = channel(:,:,2);
            case 'bggr'
                combinedImg(1:2:height,1:2:width) = channel(:,:,4);
                combinedImg(1:2:height,2:2:width) = channel(:,:,3);
                combinedImg(2:2:height,1:2:width) = channel(:,:,2);
                combinedImg(2:2:height,2:2:width) = channel(:,:,1);
        end
    end 
end