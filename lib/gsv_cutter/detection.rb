class Detection < ActiveRecord::Base
	belongs_to :building
	belongs_to :facade
	belongs_to :pano
	attr_accessible :pano_id, :state, :left_angle ,  :right_angle, :detector_id, :score, :filename
end