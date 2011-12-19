class Comment < ActiveRecord::Base
  belongs_to :commentable

  validates :body, :commentable_id, :commentable_type, :presence => true
end
