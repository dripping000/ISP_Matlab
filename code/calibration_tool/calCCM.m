function [ CCM, WB_gain, deltaE, deltaE_mean, patch_CCM_Lab ] = calCCM9( chartchannel, im, wallchannel )


if nargin<3 || isempty(wallchannel)
    wallchannel = [];
else
    wallchannel = wallchannel-im.bkd;
end
chartchannel = chartchannel-im.bkd;

% patch_xrite = dlmread('D:\read\color checker chart\X-Rite Color Checker Chart (linearRGB).txt','\t');
patch_xrite = [43.7175,21.5159,14.7404;137.567,77.7718,56.9231;
                31.1454,49.6275,85.9767;24.3034,38.2397,14.3128;
                59.8104,55.0444,112.113;34.5865,129.765,102.504;
                171.473,53.2024,6.42265;20.4561,26.6772,97.2381;
                135.985,26.0716,31.8168;28.5428,11.5225,38.2397;
                85.9767,128.236,13.0737;190.078,93.3944,6.96683;
                10.0843,11.8996,77.7718;15.6177,75.5153,16.9896;
                109.316,9.40681,11.5225;203.771,145.637,3.49403;
                126.718,23.73,76.6387;0.62811,59.8104,90.882;
                228.549,228.549,226.42;147.283,147.283,147.283;
                89.6408,89.6408,89.6408;49.6275,49.6275,48.7564;
                23.1646,23.1646,23.1646;8.75665,8.75665,8.75665]; % Xrite chart linear RGB value




g_index = strfind(im.bayer,'g');

figure(1);
clf;
imshow(chartchannel(:,:,g_index(1)),[0 2^im.bit-1]);
title('Color Checker Chart (green channel)');
m = msgbox('Click and drag a rectangle to cover all the patches, double click the rectangle when you are done.');
uiwait(m);
r = imrect;
rec_big = uint16(wait(r));
square = rec_big(3)/12;
edge_hori = square/1.8;
edge_vert = square/2;
space_hori = (rec_big(3)-square*6-edge_hori*2)/5;
space_vert = (rec_big(4)-square*4-edge_vert*2)/3;

rec_small = [];
h = [];
for i = 1:4
    for j = 1:6
        rec_temp = [rec_big(1)+edge_hori+(space_hori+square)*(j-1),rec_big(2)+edge_vert+(space_vert+square)*(i-1),square,square];         
        k = (i-1)*6+j;
        rec_small(k,:) = rec_temp;
        patch_roi_row(k,:) = (rec_temp(2)-square/3)*2:(rec_temp(2)+rec_temp(4)+square/3)*2;
        patch_roi_col(k,:) = (rec_temp(1)-square/3)*2:(rec_temp(1)+rec_temp(3)+square/3)*2;       
        h(k) = rectangle('Position',rec_temp,'EdgeColor','red');
    end
end

if ~isempty(wallchannel)
    figure(2);
    clf;
    imshow(wallchannel(:,:,2),[0 2^im.bit-1]);
    title('Lightbox wall image. (Please make sure that there is no saturation inside the red rectangle)');
    r2 = rectangle('Position',rec_big,'EdgeColor','red');
end

% region of interest from the drawn rectangle
img_roi_row = rec_big(2)*2:(rec_big(2)+rec_big(4))*2; 
img_roi_col = rec_big(1)*2:(rec_big(1)+rec_big(3))*2;

xrite = zeros(im.height,im.width,3)+100;
xrite(img_roi_row,img_roi_col,:) = 0;
for k = 1:24
    temp(1:3) = patch_xrite(k,:);
    for i = 1:3
        xrite(patch_roi_row(k,:),patch_roi_col(k,:),i) = temp(i);
    end
end

if ~isempty(wallchannel)
    wallchannel_lp = [];
    resize = 100;
    for i = 1:4
        temp = [];
        temp(:,:) = imresize(wallchannel(:,:,i),[im.height/2/resize,im.width/2/resize]);
        wallchannel_lp(:,:,i) = imresize(temp,[im.height/2,im.width/2]);
    end
    
    % Use center 64*64 pixels for calibration
    img_center = [];
    chartchannel_calibrated = [];
    ratio_map = [];
    for i = 1:4
        img_center(i) = mean(mean(wallchannel_lp(im.height/4-31:im.height/4+32,im.width/4-31:im.width/4+32,i),'omitnan'),'omitnan');
        ratio_map(:,:,i) = wallchannel_lp(:,:,i)/img_center(i);
    end
    
    chartchannel_calibrated = chartchannel./ratio_map;
else
    chartchannel_calibrated = chartchannel;
end


% intensity calibration
chart_calibrated = combineChannels( chartchannel_calibrated );

% nearest neighbour demosaic
chart_calibrated_demos = demosaicNN(chart_calibrated,im.bayer);

patch = [];
for k = 1:24
    patch(k,:) = mean(mean(chart_calibrated_demos(rec_small(k,2)*2:rec_small(k,2)*2+square*2,rec_small(k,1)*2:rec_small(k,1)*2+square*2,:),'omitnan'),'omitnan');
end
norm_calibratedratio = 1/max(patch(19,:),[],'omitnan')*max(patch_xrite(19,:),[],'omitnan');
chart_calibrated_demos = chart_calibrated_demos*norm_calibratedratio; 
patch = patch*norm_calibratedratio; 

% White balance
WB_number = 20;
WB_gain = [];
chart_WB = [];
for i = 1:3
    WB_gain(i) = patch_xrite(WB_number,i)/patch(WB_number,i);
    chart_WB(:,:,i) = chart_calibrated_demos(:,:,i)*WB_gain(i);
end

for k = 1:24
    patch_WB(k,:) = mean(mean(chart_WB(rec_small(k,2)*2:rec_small(k,2)*2+square*2,rec_small(k,1)*2:rec_small(k,1)*2+square*2,:),'omitnan'),'omitnan');
end
norm_WBratio = 1/max(patch_WB(19,:),[],'omitnan')*max(patch_xrite(19,:),[],'omitnan'); 
chart_WB = chart_WB*norm_WBratio; 
patch_WB = patch_WB*norm_WBratio; 

% CCM with intensity calibration
u = ones(3,1);
CCM = [];
for i = 1:3
    temp = patch_WB\patch_xrite(:,i)+((1-patch_xrite(:,i)'/patch_WB'*u)/(u'/(patch_WB'*patch_WB)*u))*(patch_WB'*patch_WB)\u;
    CCM(i,:) = temp;
end

chart_CCM = colorConvert(chart_WB,CCM);

for k = 1:24
    patch_CCM(k,:) = mean(mean(chart_CCM(rec_small(k,2)*2:rec_small(k,2)*2+square*2,rec_small(k,1)*2:rec_small(k,1)*2+square*2,:),'omitnan'),'omitnan');
end
norm_CCMratio = 1/max(patch_CCM(19,:),[],'omitnan')*max(patch_xrite(19,:),[],'omitnan');
chart_CCM = chart_CCM*norm_CCMratio; 

figure(3);
clf;
imshow(uint8(xrite));
title('Color Checker Chart from chart linear RGB values');

figure(4)
clf;
imshow(uint8(chart_CCM));
title('Calibrated image of Color Checker Chart');

patch_xrite_Lab = lRGB2LAB(patch_xrite);
patch_CCM_Lab = lRGB2LAB(patch_CCM);
deltaE = calcDE(patch_CCM_Lab,patch_xrite_Lab,'de00');
deltaE_mean = [];
deltaE_mean(1) = mean(deltaE,'omitnan');
deltaE_mean(2) = mean(deltaE(19:23),'omitnan');
WB_gain = WB_gain/WB_gain(2); % Normalize green channel to 1
end

