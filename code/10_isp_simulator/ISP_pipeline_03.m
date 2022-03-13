function [img_gamma, data_out] = ISP_pipeline_03(img, im, isp, params)
% This function processes a single image
% output_name = fullfile(isp.outfolder, isp.imgName);

mkdir('imge_output');
fname = params.file_name;

% Step 1: Raw image
figure(1);
clf;
imshow(double(img/2^(im.bit_depth)));
title([fname, '_input Raw']);
imwrite(double(img/2^(im.bit_depth)), [cd, '\imge_output\', fname, '_img_1.raw.bmp']);

% Step 2: Subtract black level
img = img - isp.bkd;
img(img<=0) = 0;

% step 2.5 apply digital gain
img = img * isp.dg;

% Step 3: Lens shading correction
img = img .* isp.lsc;

% Step 4: demosaic
demosaic_method = isp.dsmc_algo;
switch demosaic_method
    case 'Hamilton & Adams'
        img_demosaic = demosaicHA(img, im.bayer);
    case 'Nearist neighbor'
        img_demosaic = demosaicNN(img, im.bayer);
    case 'Marvar'
        img_demosaic = demosaic(uint16(img), im.bayer);
end

% Step 5: WB and CCM
for i = 1:3
    img_WB(:,:,i) = img_demosaic(:,:,i) * isp.WB(i);
end
img_WB = img_WB/2^(im.bit_depth);

img_CCM = colorConvert(img_WB, isp.CCM);
img_CCM(img_CCM<0) = 0;
img_CCM = uint8(img_CCM*255);
data_out.deltaE = [];
data_out.CCM = isp.CCM;
data_out.WB = isp.WB';

% Step 6: Gamma
gamma= isp.gamma;
img_gamma = ((double(uint8(img_CCM))/255).^(1/gamma))*255;
figure(6);
clf;
imshow(uint8(img_gamma), []);
title([fname, '-gamma']);
imwrite(uint8(img_gamma), [cd, '\imge_output\', fname, '_img_6.gamma.bmp']);
