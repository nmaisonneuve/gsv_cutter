class Facade < ActiveRecord::Base
	has_many :visible_rays
	belongs_to :building
end
