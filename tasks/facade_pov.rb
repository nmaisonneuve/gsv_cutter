class FacadePov
	
	attr_accessible :absolute_start, :absolute_end, :relative_start, :relative_end, :pano, :facade

	def initialize(pano_id, facade_id)
		@pano = Pano.find(pano_id)
	end

	def compute_relative
		self.relative_start = norm_angle(absolute_start  - pano.yaw_deg)
		self.relative_end = norm_angle(absolute_end  - pano.yaw_deg)
	end

	def visible_at(angle)
		if absolute_start.nil?
			self.absolute_start = angle 
		else
			self.absolute_end = angle
		end
		compute_relative
	end

	def norm_angle(angle)
		if (angle < -180)
			360 + angle
		elsif (angle > 180) 
			-360 + angle
		else 
			angle
		end
	end

	def to_s
		"absolute #{absolute_start}-#{absolute_end}, relative: #{relative_start}-#{relative_end}"
	end
end

class FacadePov2

	def initialize(id, deg_start, deg_end, width)
		self.deg_start = deg_start
		self.deg_end = deg_end
		self.width = width
		self.filename = filename
	end

	def ratio_deg(angle)
		(angle - deg_start) / (deg_end - deg_start)
	end

	def mark_angle(angle)
		pixel = ratio_deg(angle) * width
		mark_pixel(pixel)
	end

	def mark_pixel(pixel)
	  # cmd = "convert #{filename}  -crop #{width}x#{1664.to_i}+#{start}+0  building_cut.jpg"
	 	cmd = " convert #{filename}  -fill none -stroke white -draw 'line #{pixel},0 #{pixel},1664'  building_cut.jpg"
	 	p cmd
    Subexec.run cmd, :timeout => 0
	end

	def cut_angles(deg1, deg2)
		p1 = ratio_deg(deg1) * width
		p2 = ratio_deg(deg2) * width
		cut_from_pixels(p1, p2)
	end

  def cut_pixels(pixel1, pixel2)
	  width = pixel2 - pixel1
	  start = pixel1
	  if (width < 0)
	  	start = pixel2
	  	width = - width
	  end
	  # cmd = "convert #{filename}  -crop #{width}x#{1664.to_i}+#{start}+0  building_cut.jpg"
	 	cmd = " convert #{filename}  -fill none -stroke white -draw 'line #{start},0 #{start},1664'  building_cut.jpg"
	 	p cmd
    Subexec.run cmd, :timeout => 0
	end
end