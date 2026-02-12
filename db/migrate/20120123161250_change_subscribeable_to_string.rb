class ChangeSubscribeableToString < ActiveRecord::Migration[8.1]
  def self.up
    change_column :subscribes, :subscribeable_id, :string #, references: nil
  end

  def self.down
    change_column :subscribes, :subscribeable_id, :integer
  end
end
