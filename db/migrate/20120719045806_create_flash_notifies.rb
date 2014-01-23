class CreateFlashNotifies < ActiveRecord::Migration
  def change
    create_table :flash_notifies do |t|
      t.text    :body_ru,   null: false
      t.text    :body_en,   null: false
      t.string  :status,    null: false
      t.boolean :published, null: false, default: true
      t.timestamps
    end
  end
end
