class CreateDownloads < ActiveRecord::Migration
  def self.up
    create_table :downloads do |t|
      t.string :name, null: false
      t.string :version
      t.string :distro
      t.string :platform
      t.integer :counter, default: 0

      t.timestamps
    end
  end

  def self.down
    drop_table :downloads
  end
end
