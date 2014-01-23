class ChangeCommentableIdToDecimal < ActiveRecord::Migration
  def up
    add_column :comments, :commentable_id_tmp, :decimal, precision: 50, scale: 0
    Comment.reset_column_information
    Comment.all.each {|c| c.update_column :commentable_id_tmp, (c.commentable_type == 'Grit::Commit' ? c.commentable_id.hex : c.commentable_id.to_i)}
    remove_column :comments, :commentable_id
    rename_column :comments, :commentable_id_tmp, :commentable_id
  end

  def down
    add_column :comments, :commentable_id_tmp, :string
    Comment.reset_column_information
    Comment.all.each {|c| c.update_column :commentable_id_tmp, (c.commentable_type == 'Grit::Commit' ? c.commentable_id.to_s(16) : c.commentable_id.to_s)}
    remove_column :comments, :commentable_id
    rename_column :comments, :commentable_id_tmp, :commentable_id
  end
end
