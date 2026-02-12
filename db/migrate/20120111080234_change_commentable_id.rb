class ChangeCommentableId < ActiveRecord::Migration[8.1]
  def self.up
    change_column :comments, :commentable_id, :string #, references: nil
  end

  def self.down
    change_column :comments, :commentable_id, :integer
  end
end
