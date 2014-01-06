class Ret < ActiveRecord::Migration
  def up
  	change_table(:panos) do |t|
  		t.change(:panoID, :string, null: false)
		end
  end

  def down
  end
end
