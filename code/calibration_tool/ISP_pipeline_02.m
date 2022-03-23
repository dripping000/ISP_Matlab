function [img_gamma, data_out] = ISP_pipeline_02(img, im, isp, params)
% This function processes a single image
%output_name = fullfile(isp.outfolder,isp.imgName);

mkdir('imge_output');
fname = params.file_name;

% if contains(im.bit,'uint8')
%     im.bit = 8;
% elseif contains(im.bit,'uint16')
%     im.bit = 16;
% else
%     im.bit =32;
% end

% im.bitshift= str2num(im.bitshift);


% Step 1: Raw image
% if get(handles.rawDisplay_cb, 'Value')
%     figure(1);
%     clf;
%     
%     imshow(double(img/2^(im.bit_depth)));
%     title([fname,'_input Raw']);
% end
% if get(handles.rawBMP_cb, 'Value')
%     imwrite(double(img/2^(im.bit_depth)), [cd, '\imge_output\', fname, '_img_1.raw.bmp']);
% end
imwrite(double(img/2^(im.bit_depth)), [cd, '\imge_output\', fname, '_img_1.raw.bmp']);


% Step 2: Subtract black level
img(1:2:end, 1:2:end) = img(1:2:end, 1:2:end) - isp.bkd(1);  % (1, 1)
img(1:2:end, 2:2:end) = img(1:2:end, 2:2:end) - isp.bkd(2);  % (1, 2)
img(2:2:end, 1:2:end) = img(2:2:end, 1:2:end) - isp.bkd(3);  % (2, 1)
img(2:2:end, 2:2:end) = img(2:2:end, 2:2:end) - isp.bkd(4);  % (2, 2)
img(img<=0) = 0;

% if get(handles.bkdDisplay_cb,'Value')
%     figure(2);
%     clf;
%     imshow(double(img/2^(im.bit_depth)));
%     title([fname ,'-Subtract black level Raw']);
% end
% if get(handles.bkdBMP_cb,'Value')
%     imwrite(double(img/2^(im.bit_depth)),[cd, '\imge_output\',fname,'_img_2.BLsubtract.bmp']);
% end
imwrite(double(img/2^(im.bit_depth)),[cd, '\imge_output\',fname,'_img_2.BLsubtract.bmp']);


% step 2.5 apply digital gain
img=img * isp.dg;


% Step 3: Lens shading correction
if isempty(isp.lsc)
    isp.lsc=1;
end

img = img.*isp.lsc;
% if get(handles.LSCdisplay_cb,'Value')
%     figure(3);
%     clf;
%     imshow(double(img/2^(im.bit_depth)));
%     title([fname,'-LSC Raw']);
% end
% if get(handles.LSCbmp_cb,'Value')
%     imwrite(double(img/2^(im.bit_depth)),[cd, '\imge_output\',fname,'_img_3.LSC.bmp']);
% end
imwrite(double(img/2^(im.bit_depth)),[cd, '\imge_output\',fname,'_img_3.LSC.bmp']);


% Step 4: demosaic
% demosaic_method = get(handles.demosaicMethod_pm,'Value');
demosaic_method = isp.dsmc_algo;
switch demosaic_method
    case 'Hamilton & Adams'
        img_demosaic = demosaicHA(img, im.bayer);
    case 'Nearist neighbor'
        img_demosaic = demosaicNN(img, im.bayer);
    case 'Marvar'
        img_demosaic = demosaic(uint16(img), im.bayer);
end
% if get(handles.demosaicDisplay_cb,'Value')
%     figure(4);
%     clf;
%     imshow(double(img_demosaic/2^(im.bit_depth)));
%     title([fname,'-demosaic RGB']);
% end
% if get(handles.demosaicBMP_cb,'Value')
%     imwrite(double(img_demosaic/2^(im.bit_depth)),[cd, '\imge_output\',fname,'_', demosaic_method,'_img_4.demosaic.bmp']);
% end
imwrite(double(img_demosaic/2^(im.bit_depth)),[cd, '\imge_output\',fname,'_', demosaic_method,'_img_4.demosaic.bmp']);


% Step 5: WB and CCM
% if get(handles.CCMvalue_rb,'Value')
%     isp.CCM = get(handles.CCM_matrix,'Data');
%     isp.WB = get(handles.WB_gain_matrix,'Data');

if 0  % params.ccm_enable
    for i = 1:3
        img_WB(:,:,i) = img_demosaic(:,:,i)*isp.WB(i);
    end
    img_WB = img_WB/2^(im.bit_depth);
    img_CCM = colorConvert(img_WB,isp.CCM);
    img_CCM= uint8(img_CCM*255);
    data_out.deltaE = [];
else
    % rec_big = get(handles.position_matrix,'Data');  % big rectangle (chart)
    rec_big = isp.rec_big;
    if rec_big(1)<1 || rec_big(2)<1 || rec_big(3)< 37 ||rec_big(4)< 37
        msgbox('Wrong chart position!');
        error('Wrong chart position!');
    else
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
        
        square = rec_big(3)/12;
        edge_hori = square/1.8;
        edge_vert = square/2;
        
        space_hori = (rec_big(3)-square*6-edge_hori*2)/5;
        space_vert = (rec_big(4)-square*4-edge_vert*2)/3;
        
        rec_small = [];  % small rectangle (each patch)
        h = [];
        for i = 1:4
            for j = 1:6
                rec_temp = [rec_big(1)+edge_hori+(space_hori+square)*(j-1), rec_big(2)+edge_vert+(space_vert+square)*(i-1),square,square];
                k = (i-1)*6+j;
                rec_small(k,:) = rec_temp;
            end
        end
        
        for k = 1:24
            img_roi_row(k,:) = rec_small(k,2)*2:rec_small(k,2)*2+square*2;
            img_roi_col(k,:) = rec_small(k,1)*2:rec_small(k,1)*2+square*2;
        end
        
        patch = [];
        for k = 1:24
            patch(k,:) = mean(mean(img_demosaic(img_roi_row(k,:), img_roi_col(k,:), :), 'omitnan'), 'omitnan');
        end        
        
        % White balance
        WB_number = 20;
        isp.WB = [1 1 1]';
        img_WB = [];
        isp.WB(1) = patch(WB_number,2)/patch(WB_number,1);
        isp.WB(3) = patch(WB_number,2)/patch(WB_number,3);
        for i = 1:3
            img_WB(:, :, i) = img_demosaic(:, :, i) * isp.WB(i);
            patch_WB(:, i) = patch(:, i) * isp.WB(i);
        end        
        imwrite(double(img_WB/2^(im.bit_depth)),[cd, '\imge_output\',fname,'_', demosaic_method,'_img.awb.bmp']);

        % Normalize to color chart linear value
        patch_WB_19 = mean(mean(img_WB(rec_small(19,2)*2 : rec_small(19,2)*2+square*2, rec_small(19,1)*2 : rec_small(19,1)*2+square*2,:), 'omitnan'), 'omitnan');
        norm_WBratio = 1 / max(patch_WB_19(:), [], 'omitnan') * max(patch_xrite(19,:));
        img_WB = img_WB * norm_WBratio;
        patch_WB = patch_WB * norm_WBratio;
        
        % CCM
        u = ones(3, 1);
        isp.CCM = [];
        for i = 1:3
            temp = patch_WB \ patch_xrite(:, i) + ((1 - patch_xrite(:, i)' / patch_WB' * u) / (u' / (patch_WB' * patch_WB) * u)) * (patch_WB' * patch_WB) \ u;
            isp.CCM(i, :) = temp;
        end
        img_CCM = colorConvert(img_WB, isp.CCM);
        img_CCM(img_CCM<0) = 0;
        
        img_rect = img_CCM;
        for k = 1:24
            temp = [];
            temp = mean(mean(img_CCM(img_roi_row(k, :), img_roi_col(k, :), :), 'omitnan'), 'omitnan');
            patch_CCM(k, :) = mean(mean(img_CCM(img_roi_row(k, :), img_roi_col(k, :), :), 'omitnan'), 'omitnan');
            img_rect(img_roi_row(k, 1:5), img_roi_col(k, :), :) = 255 - img_rect(img_roi_row(k, 1:5), img_roi_col(k, :), :);
            img_rect(img_roi_row(k, end-5+1:end), img_roi_col(k, :), :) = 255 - img_rect(img_roi_row(k, end-5+1:end), img_roi_col(k,:), :);
            img_rect(img_roi_row(k, :), img_roi_col(k, 1:5), :) = 255 - img_rect(img_roi_row(k, :), img_roi_col(k, 1:5), :);
            img_rect(img_roi_row(k, :), img_roi_col(k, end-5+1:end), :) = 255 - img_rect(img_roi_row(k, :), img_roi_col(k, end-5+1:end), :);
        end
        imwrite(uint8(img_rect), [cd, '\imge_output\', fname, '_img_ROI.bmp']);   

        patch_xrite_Lab = lRGB2LAB(patch_xrite);
        patch_CCM_Lab = lRGB2LAB(patch_CCM);
        deltaE = calcDE(patch_CCM_Lab, patch_xrite_Lab, 'de00');
        deltaE_mean = [];
        deltaE_mean(1) = mean(deltaE, 'omitnan');
        deltaE_mean(2) = mean(deltaE(19:23), 'omitnan');
        
        %set(handles.CCM_matrix,'Data',isp.CCM);
        %set(handles.WB_gain_matrix,'Data',isp.WB);
        %set(handles.deltaE_str,'String',num2str(deltaE_mean(1)));
        %if deltaE_mean(1)<=2.5 && deltaE_mean(1)>=0
        %    set(handles.deltaE_str,'BackgroundColor','Green');
        %else
        %    set(handles.deltaE_str,'BackgroundColor','Red');
        %end
        
        %set(handles.deltaE_gray_str,'String',num2str(deltaE_mean(2)));
        %if deltaE_mean(2)<=2.5 && deltaE_mean(2)>=0
        %    set(handles.deltaE_gray_str,'BackgroundColor','Green');
        %else
        %    set(handles.deltaE_gray_str,'BackgroundColor','Red');
        %end
        
        data_out.deltaE = deltaE_mean;
    end
end

% if get(handles.CCMdisplay_cb,'Value')
%     figure(5);
%     clf;
%     imshow(uint8(img_CCM),[]);
%     title([fname,'-CCM and WB gain applied']);
% end
% if get(handles.CCMbmp_cb,'Value')
%     imwrite(uint8(img_CCM),[cd, '\imge_output\',fname,'_img_5.CCM.bmp']);
% end
imwrite(uint8(img_CCM),[cd, '\imge_output\',fname,'_img_5.CCM.bmp']);


data_out.CCM = isp.CCM;
data_out.WB = isp.WB';


% Step 6: Gamma
%gamma = 1/str2double(get(handles.gamma_str,'String'));
gamma= isp.gamma;
img_gamma = ((double(uint8(img_CCM))/255).^(1/gamma))*255;

% if get(handles.gammaDisplay_cb,'Value')
%     figure(6);
%     clf;
%     imshow(uint8(img_gamma),[]);
%     title([fname,'-gamma']);
% end
% if get(handles.gammaBMP_cb,'Value')
%     imwrite(uint8(img_gamma),[cd, '\imge_output\',fname,'_img_6.gamma.bmp']);
% end
imwrite(uint8(img_gamma),[cd, '\imge_output\',fname,'_img_6.gamma.bmp']);
