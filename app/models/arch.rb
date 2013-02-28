# -*- encoding : utf-8 -*-
class Arch < ActiveRecord::Base
  has_many :build_lists, :dependent => :destroy

  validates :name, :presence => true, :uniqueness => true

  scope :recent, order("#{table_name}.name ASC")
end
