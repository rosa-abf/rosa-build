class Right < ActiveRecord::Base
  before_save :generate_name

  scope :for_controller, lambda { |cont| {:conditions => ['controller = ?', cont.controller_name]}}

  class << self
    def by_controller
      all.inject({}) do |h, i|
        h[i.controller] ||= []
        h[i.controller] << i
        h
      end
    end
  end
  protected
    NAME_TEMPL = 'Right to perform %s action.'

    def generate_name
      self.name = sprintf(NAME_TEMPL, action) unless name and name.size == 0
    end
end
