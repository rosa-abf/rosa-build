class ChangeSubscribeableToString < ActiveRecord::Migration
  def self.up
    change_column :subscribes, :subscribeable_id, :string, references: nil
  end

  def self.down
    change_column :subscribes, :subscribeable_id, :integer
  end
end
