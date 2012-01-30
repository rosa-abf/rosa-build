# -*- encoding : utf-8 -*-
class Settings::Notifier < ActiveRecord::Base
  belongs_to :user

  validates :user_id, :presence => true
end
