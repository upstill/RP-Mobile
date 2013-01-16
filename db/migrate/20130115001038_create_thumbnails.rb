class CreateThumbnails < ActiveRecord::Migration
  def change
    create_table :thumbnails do |t|
      t.text :url
      t.text :thumbdata
      t.integer :status # Generally, a URL return code
      t.string  :status_text # Explanation for the status
      t.integer :thumbwid, default: 120
      t.integer :thumbht, default: 120

      t.timestamps
    end
    add_index :thumbnails, :url,                :unique => true
    add_column :recipes, :thumbnail_id, :integer
  end
end
