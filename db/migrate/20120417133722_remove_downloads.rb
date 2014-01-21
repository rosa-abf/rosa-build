class RemoveDownloads < ActiveRecord::Migration
  def up
    drop_table :downloads
  end

  def down
    create_table "downloads", force: true do |t|
      t.string   "name", null: false
      t.string   "version"
      t.string   "distro"
      t.string   "platform"
      t.integer  "counter",    default: 0
      t.datetime "created_at"
      t.datetime "updated_at"
    end
  end
end
