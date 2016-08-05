class CreateSpiders < ActiveRecord::Migration
  def change
    create_table :spiders do |t|
    	t.string :source, :null => false
      t.string :title, :null => false
      t.string :url, :null => false
      t.string :rule
      t.integer :status

      t.timestamps null: false
    end
  end
end
