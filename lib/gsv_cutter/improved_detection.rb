class ImprovedDetection < ActiveRecord::Base
	
  attr_accessible :detection_id, :detector_id, :panoid ,:score, :building_id , :location_detection, :distance_detection, :year_construction ,:period_construction ,:filename

end