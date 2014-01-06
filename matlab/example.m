% panoramic Google Street View image
input_path = '~/Documents/work/gsv_cutter/52FVJSQ2oag9htUQFNDFrQ_zoom_4.jpg';

% perspective/cutout image
output_path = '~/Documents/test_v3.jpg';

% horizontal orientation 
% 0 = center, 90 = left side, 270 = right side
yaw_deg = 0;

% vertical orientation
pitch_deg = 8;

% field of view 
field_of_view_deg = 60;

% reading panoramic image
pano_img = imread(input_path);

output_size.width = 1000; 
output_size.height = 700;

% transform spherical coordinate and  cutout a perspective
output = spher2pers(pano_img, yaw_deg, pitch_deg, field_of_view_deg, output_size);

% save the perspective
imwrite(output,output_path);
