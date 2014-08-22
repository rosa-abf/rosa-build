class ChangeCommentableId < ActiveRecord::Migration
  def self.up
    change_column :comments, :commentable_id, :string, references: nil
  end

  def self.down
    change_column :comments, :commentable_id, :integer
  end
end
