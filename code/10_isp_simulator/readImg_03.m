function [ img, im ] = readImg_03( imgpath, im, excludePD )

if nargin<3, excludePD = true; end

im.type = lower(im.type);

switch im.type
    case {'raw', 'bin'}
        if im.bit_depth <= 8 && im.bit_depth > 0
            format = 'uint8';
        elseif im.bit_depth <=16 && im.bit_depth>8
            format = 'uint16';
        else
            error('im.bit error! Check your image bit!');
        end
        
        fin = fopen(imgpath, 'r');
        if strcmpi(im.type, 'bin')
            wh = fread(fin, 2, format);
            im.rawWidth = wh(1);
            im.rawHeight = wh(2);
        end
        
        img_raw = [];
        img = [];
        img_raw = fread(fin, im.rawWidth*im.rawHeight, format);
        fclose(fin);
        img = reshape(img_raw, im.rawWidth, im.rawHeight);
        img = img';
        
    case 'bmp'
        img = imread(imgpath);
        
    case 'qc'
        numBytesToRead = ceil(im.rawHeight*im.rawWidth*8/6);
        % read the data to memory
        fid = fopen(imgpath, 'rb');
        data = fread(fid, numBytesToRead, '*uint8');
        fclose(fid);
        
        % perform first time LUT
        % create LUT
        LUT8 = uint8(bin2dec(fliplr(dec2bin(0:255,8))));
        data=intlut(data,LUT8);
        
        % perform organization
        data = reshape(data, 8, []);
        data2 = zeros(6, size(data,2), 'uint16');
        data = uint16(data);
        data2(1,:) = data(1,:)*4+uint16(floor(single(data(2,:))/64));
        data2(2,:) = data(2,:)*16+uint16(floor(single(data(3,:))/16));
        data2(3,:) = data(3,:)*64+uint16(floor(single(data(4,:))/4));
        data2(4,:) = data(4,:)*256+data(5,:);
        data2(5,:) = data(6,:)*4+uint16(floor(single(data(7,:))/64));
        data2(6,:) = data(7,:)*16+uint16(floor(single(data(8,:))/16));
        
        data2 = mod(data2, 1024);
        % perform second time LUT
        LUT10 = uint16(bin2dec(fliplr(dec2bin(0:1023,10))));
        LUT16 = zeros(65536, 1, 'uint16');
        LUT16(1:1024) = LUT10;
        data2 = intlut(data2(:), LUT16);
        
        % reshape to proper size
        img = reshape(data2,im.rawWidth, im.rawHeight);
        img = img';
        
    case 'mipi'
        % open file
        fid = fopen(imgpath, 'rb');
        stride = 8;
        
        % calculate bytes to read for each row
        widthNumBytes = ceil(im.rawWidth*5/4/stride)*stride;
        
        % read in data
        data = fread(fid,widthNumBytes*im.rawHeight, '*uint8');
        fclose(fid);
        
        % reshape data
        data = reshape(data,widthNumBytes, im.rawHeight);
        
        % extract every four of five bytes
        img = data(mod(1:widthNumBytes,5)>0, :);
        img = img(1:im.rawWidth, :);
        
        % get P0
        imgExt = single(data(5:5:end, :));  % need to convert to single for floor operation
        imgExt1 = mod(imgExt, 4);
        
        % get P1
        imgExt = floor(imgExt/4);
        imgExt2 = mod(imgExt, 4);
        
        % get P2
        imgExt = floor(imgExt/4);
        imgExt3 = mod(imgExt, 4);
        
        % get P3
        imgExt4 = floor(imgExt/4);
        
        % cat P0-P3
        imgLSB = cat(3,imgExt1, imgExt2, imgExt3, imgExt4);
        
        % permute to change storage sequence
        imgLSB = permute(imgLSB, [3,1,2]);
        
        % reshape to im.rawWidth * im.rawHeight
        imgLSB = reshape(imgLSB, im.rawWidth, im.rawHeight);
        
        % add back to original image
        img = uint16(img)*4 + uint16(imgLSB);
        img = img';
        
    otherwise
        error('Unknown type!');
        
end

if isfield(im, 'PD') && excludePD
    img(im.PD) = nan;
end

if isfield(im, 'edge') && sum(im.edge) > 0
    img = img((im.edge(1)+1):(im.rawHeight-im.edge(2)), (im.edge(3)+1):(im.rawWidth-im.edge(4)));
end
    
[im.height, im.width] = size(img);

if strcmpi(im.cell, 'quad')
    temp = zeros(im.height, im.width);
    temp(1:4:end,:) = img(1:4:end,:);
    temp(2:4:end,:) = img(3:4:end,:);
    temp(3:4:end,:) = img(2:4:end,:);
    temp(4:4:end,:) = img(4:4:end,:);
    img = zeros(im.height, im.width);
    img(:,1:4:end) = temp(:,1:4:end);
    img(:,2:4:end) = temp(:,3:4:end);
    img(:,3:4:end) = temp(:,2:4:end);
    img(:,4:4:end) = temp(:,4:4:end);
end
