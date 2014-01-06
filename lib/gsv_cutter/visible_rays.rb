class VisibleRay < ActiveRecord::Base
	belongs_to :rays
	belongs_to :pano
	belongs_to :facade
end


# hit a building and see how far I can go from this building.
