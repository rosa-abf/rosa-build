# -*- encoding : utf-8 -*-
class Category < ActiveRecord::Base
  has_many :projects, :dependent => :nullify

  validates :name, :presence => true

  default_scope order('categories.name')

  has_ancestry
end
