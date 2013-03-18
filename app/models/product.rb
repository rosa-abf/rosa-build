class Product < ActiveRecord::Base
  include Modules::Models::TimeLiving

  belongs_to :platform
  belongs_to :project
  has_many :product_build_lists, :dependent => :destroy

  validates :name, :presence => true, :uniqueness => {:scope => :platform_id}
  validates :project_id, :presence => true
  validates :main_script, :params, :length => { :maximum => 255 }

  scope :recent, order("#{table_name}.name ASC")

  attr_accessible :name,
                  :description,
                  :project_id,
                  :main_script,
                  :params,
                  :platform_id
  attr_readonly :platform_id

  def full_clone(attrs = {})
    dup.tap do |c|
      attrs.each {|k,v| c.send("#{k}=", v)}
      c.time_living = c.time_living.to_i / 60 # see: Modules::Models::TimeLiving#convert_time_living
      c.platform_id = nil
      c.product_build_lists = []
      c.updated_at = nil; c.created_at = nil
    end
  end

end
