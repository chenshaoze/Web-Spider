class CreateTasks < ActiveRecord::Migration
  def change
    create_table :tasks do |t|
      t.string :source
      t.datetime :last_item_datetime

      t.timestamps null: false
    end
  end
end
