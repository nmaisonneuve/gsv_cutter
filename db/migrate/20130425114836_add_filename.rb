class AddFilename < ActiveRecord::Migration
  def up
		change_table(:panos) do |t|
			t.string :filepath
		end
  end

  def down
  end
end
