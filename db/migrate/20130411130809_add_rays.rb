class AddRays < ActiveRecord::Migration
 def up
  	create_table :rays do |t|
  	 t.line_string :geom, :geographic => true, :srid => 4326
  	 t.float :angle
  	 t.references :pano
  	 t.timestamps
  	end

		add_index :rays, :geom, :spatial => true
  end

  def down
  end
end
