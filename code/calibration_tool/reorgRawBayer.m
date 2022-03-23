function CH_rggb = reorgRawBayer(img, im)


CH_rggb = [];
if strcmpi(im.bayer,'mono') || strcmpi(im.cell,'mono')
    CH_rggb(:,:,1,:) =  img;
else
    switch lower(im.bayer)
        case 'rggb'
            CH_rggb(:,:,1,:) = img(1:2:end,1:2:end,:); %upper left;
            CH_rggb(:,:,2,:) = img(1:2:end,2:2:end,:); %upper right
            CH_rggb(:,:,3,:) = img(2:2:end,1:2:end,:); %lower left
            CH_rggb(:,:,4,:) = img(2:2:end,2:2:end,:); %lower right
        case 'bggr'
            CH_rggb(:,:,4,:) = img(1:2:end,1:2:end,:);
            CH_rggb(:,:,3,:) = img(1:2:end,2:2:end,:);
            CH_rggb(:,:,2,:) = img(2:2:end,1:2:end,:);
            CH_rggb(:,:,1,:) = img(2:2:end,2:2:end,:);
        case 'gbrg'
            CH_rggb(:,:,3,:) = img(1:2:end,1:2:end,:);
            CH_rggb(:,:,4,:) = img(1:2:end,2:2:end,:);
            CH_rggb(:,:,1,:) = img(2:2:end,1:2:end,:);
            CH_rggb(:,:,2,:) = img(2:2:end,2:2:end,:);
        case 'grbg'
            CH_rggb(:,:,2,:) = img(1:2:end,1:2:end,:);
            CH_rggb(:,:,1,:) = img(1:2:end,2:2:end,:);
            CH_rggb(:,:,4,:) = img(2:2:end,1:2:end,:);
            CH_rggb(:,:,3,:) = img(2:2:end,2:2:end,:);
        otherwise
            error('Unknown Bayer Pattern!');
    end
    
    
end