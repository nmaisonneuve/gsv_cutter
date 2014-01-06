%%
%% Transform panoramic images into perspective image
%%
%% inputpath: path of the panoramic image
%% outputpath: path of the output cutted image
%% _hfov: horizontal filled of view [in degree]
%% _yaw: horizontal angle (0=front side , 180=back side, 90=left side, 270=right side)
%% _pitch : vertical angle (0 =bottom , 180 = sky)
%% _axial: rotat
function out = spher2pers(pano_img, yaw_, pitch_, steep_angle_, hfov_, output_size);

   % input  image size
   [iimh, iimw, ~] = size(pano_img);

	%% Perspective view parameters
    oimh = output_size.height;   
	oimw = output_size.width;    % output image size
    
	hfov = hfov_ * (pi/180.0); 	% horizontal filled of view [rad]
	f = oimw/(2*tan(hfov/2)); % focal length [pix]
	
    yaw = yaw_ * pi/180.0; % horizontal angle (0=front side , 180=back side, 90=left side, -90=right side)
	
   % pitch = pitch_ * pi/180.0; 	% vertical angle
	pitch = pitch_;
  pitch_2 = 0.0; %steep_angle_; 	% axial angle (required if steep street)

	%printf("\nparameters: focal length %f\npitch: %f\nhfov: %f\n,yaw: %f\n",f,pitch, hfov, yaw)

	ouc = (oimw+1)/2;
	ovc = (oimh+1)/2;             % output image center
	iuc = (iimw+1)/2;
	ivc = (iimh+1)/2;             % input image center
	sw = iimw/ (2 * pi);
	sh = iimh/ pi;

	%% Tangent plane to unit sphere mapping
	[X Y] = meshgrid(1:oimw, 1:oimh);
	X = X-ouc;   
	Y = Y-ovc; % shift origin to the image center
	Z = f+0*X;
	PTS = [X(:)'; Y(:)'; Z(:)'];

	% Transformation for oitch angle
	  Tx = expm([0     -pitch_2/180*pi           0        ;...
	             pitch_2/180.0*pi       0       -pitch/180.0*pi;
	             0 pitch/180.0*pi   0]);

	% rotation w.r.t x-axis about pitch angle
	PTSt = Tx * PTS;
	Xt=reshape(PTSt(1,:),oimh, oimw);
	Yt=reshape(PTSt(2,:),oimh, oimw);
	Zt=reshape(PTSt(3,:),oimh, oimw);
	THETA = atan2(Xt, Zt);                 % cartesian to spherical
	PHI = atan(Yt./sqrt(Xt.^2+Zt.^2));
	THETA = THETA + yaw;
	U = sw * THETA + iuc;
	V = sh * PHI  + ivc;
    
    % interpolation
	out=iminterpnn(pano_img, U,V);
end