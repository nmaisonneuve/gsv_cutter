class PanosFacade < ActiveRecord::Base
	
	attr_accessible :absolute_start, :absolute_end, :relative_start, :relative_end, :pano, :facade_id, :geom, :facade_time_period, :start_ray_id, :end_ray_id, :center_ray_id	, :distance

	belongs_to :pano
	belongs_to :facade

	@point_start
	@point_end
	@distances

	def post_processing(type_point = "latlng")
		compute_relative_angles
		if valid_pov?
			compute_geom(type_point)
			self.pov_angle = (self.relative_end- self.relative_start).abs
			# self.distance = @distances.inject{ |sum, el| sum + el }.to_f / arr.size
		end
		self.save
	end

	def pitch_from_height(building_height = 2.0)
		Math::tan(building_height.to_f/self.distance.to_f) * 180.0 / Math::PI
	end

	def compute_relative_angles
		self.relative_start = norm_angle(absolute_start  - pano.yaw_deg) unless absolute_start.nil?
		self.relative_end = norm_angle(absolute_end  - pano.yaw_deg) unless absolute_end.nil?
	end

	def valid_pov?
		(!(absolute_end.nil? || absolute_start.nil?)) && ((relative_start >= 0 && relative_end >= 0) || (relative_start <= 0 && relative_end <= 0))
	end

	def side
	 if (self.relative_start < 0)
	 	:left
	 else
	 	:right
	 end
	end

	def mark_angles
		pano.mark_angle(self.relative_start)
		pano.mark_angle(self.relative_end)
	end

	def compute_geom(type_point = "latlng")
		self.geom = "LINESTRING( #{extract_geom(@point_start)}, #{extract_geom(pano[type_point].to_s)}, #{extract_geom(@point_end)})"
	end

	def extract_geom(point)
		/POINT[ ]?\(([\d|\.]+ [\d|\.]+)\)/.match(point).to_a[1]
	end

	def visible_at(point, angle, distance)
		if absolute_start.nil?
			self.absolute_start = angle 
			@point_start = point
			@distances = []
		else
			self.absolute_end = angle
			@point_end = point
		end
		@distances << distance
	end

	def norm_angle(angle)
		if (angle < -180)
			360.0 + angle
		elsif (angle > 180) 
			- 360.0 + angle
		else 
			angle
		end
	end

	def to_s
		%Q{
#{pano.id}-#{facade_id} 
absolute angles (#{absolute_start}, #{absolute_end}),
yaw_deg: #{pano.yaw_deg},
relative angles: (#{relative_start}, #{relative_end})
side: #{side},
geom : #{self.geom}
		}
	end
end