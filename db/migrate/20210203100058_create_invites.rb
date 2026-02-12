class CreateInvites < ActiveRecord::Migration[8.1]
  def change
    create_table :invites do |t|
      t.references :user, index: true, foreign_key: true, null: false
      t.references :invited_user, index: true, foreign_key: false, null: true
      t.string :invite_key, index: true, default: ''

      t.timestamps null: false
    end
  end
end
