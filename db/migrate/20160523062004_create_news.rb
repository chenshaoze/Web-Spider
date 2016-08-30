class CreateNews < ActiveRecord::Migration
  def change
    create_table :news do |t|
    	t.string :source, :null => false
      t.integer :sync
      t.string :author
      t.string :title
      t.string :url
      t.datetime :publish_at
      # t.column :content, :longtext
      t.column :html, :longtext
      t.integer :is_pic_news
      t.string :pic_url

      t.timestamps null: false
    end
  end
end
