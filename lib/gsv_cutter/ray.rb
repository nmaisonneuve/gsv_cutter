class Ray < ActiveRecord::Base
	attr_accessible :geom, :angle, :line, :type
	belongs_to :pano

	def lat
  	geom[0].y
  end

  def lng
  	geom[0].x
  end

end