function img_YUV = lRGB2YUV( img_lRGB )


YUV_ratio = [0.299,0.587,0.114;-0.14713,-0.28886,0.436;0.615,-0.51499,-0.10001];
img_YUV = colorConvert(img_lRGB, YUV_ratio);

end

