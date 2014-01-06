class ChangePanos < ActiveRecord::Migration
  def up
  	change_table(:panos) do |t|
  		t.rename :model , :raw_json
  		t.integer :num_zoom_level
		end
  end

  def down
  end
end
