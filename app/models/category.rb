# -*- encoding : utf-8 -*-
class Category < ActiveRecord::Base
  has_many :projects, :dependent => :nullify

  validates :name, :presence => true

  scope :default_order, order('categories.name')

  has_ancestry
end
