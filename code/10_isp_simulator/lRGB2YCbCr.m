function img_YCbCr = lRGB2YCbCr( img_lRGB, bit )


YCbCr_ratio = [0.299,0.587,0.114;-0.168736,-0.331264,0.5;0.5,-0.418688,-0.081312];

img_YCbCr = colorConvert(img_lRGB, YCbCr_ratio);
% img_YCbCr(:,:,2:3) = img_YCbCr(:,:,2:3)+2^(bit-1);
end

