class CreateNews < ActiveRecord::Migration
  def change
    create_table :news do |t|
    	t.string :source, :null => false
      t.string :title
      t.string :url
      t.datetime :publish_at
      t.column :content, :longtext
      t.column :html, :longtext

      t.timestamps null: false
    end
  end
end
