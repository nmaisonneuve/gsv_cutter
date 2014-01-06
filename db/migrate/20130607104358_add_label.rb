class AddLabel < ActiveRecord::Migration
  def up
		change_table(:panos) do |t|
			t.integer :label
		end
  end

  def down
  end
end
