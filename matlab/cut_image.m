
function cut_image(input_path, yaw_deg, pov, pitch_deg, steep_angle, output_height, output_width, output_path);
  % read the panoramic images
  pano_img = imread(input_path);

  
  field_of_view_deg = pov;
  output_size.width = output_width; 
  output_size.height = output_height;

  % printf("\n%f", output_size.width);
  % printf("\n%f", output_size.height);


  % transform into spherical coordinates and cut a perspective
  output_img = spher2pers(pano_img, yaw_deg, pitch_deg, steep_angle, field_of_view_deg, output_size);

  % save the perspective
  imwrite(output_img,output_path);
end