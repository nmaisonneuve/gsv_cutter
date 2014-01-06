class AugmentedPanos < ActiveRecord::Migration
  def up
  	change_table(:panos) do |t|
  		t.rename :photographerPOV, :yaw_deg
  		t.point :original_latlng, :geographic => true, :srid => 4326
  		t.date :image_date
  		t.float :elevation
  		t.string :description
  		t.string :street
  		t.string :region
  		t.string :country
  		t.text :model
  		t.datetime :processed_at
  		t.string :links
  		# index
  		#t.index :panoID, :spatial => true
  		t.index :original_latlng, :spatial => true
		end
  end

  def down
  end
end
