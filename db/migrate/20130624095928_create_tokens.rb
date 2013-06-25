class CreateTokens < ActiveRecord::Migration

  def change
    create_table :tokens do |t|
      t.integer :subject_id,    :null => false
      t.string  :subject_type,  :null => false
      t.integer :creator_id,    :null => false
      t.integer :updater_id
      t.string  :status,        :default => 'active'
      t.text    :description
      t.string  :authentication_token, :null => false

      t.timestamps
    end
    add_index :tokens, :authentication_token, :unique => true
    add_index :tokens, [:subject_id, :subject_type]
  end

end
