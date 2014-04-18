class CreateNodeInstructions < ActiveRecord::Migration
  def change
    create_table :node_instructions do |t|
      t.integer :user_id,             null: false
      t.text :encrypted_instruction,  null: false
      t.text :output
      t.string :status

      t.timestamps
    end
  end
end
