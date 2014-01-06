class AddGsvTable < ActiveRecord::Migration
  def up
  	create_table :panos do |t|
  	 t.point :latlng, :geographic => true, :srid => 4326
  	 t.string :panoID
  	 t.float :photographerPOV
  	 t.timestamps
  	end

		add_index :panos, :panoID, :unique => true
		add_index :panos, :latlng, :spatial => true
  end

  def down
  end
end
