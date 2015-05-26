class EventLog < ActiveRecord::Base
  belongs_to :user
  belongs_to :eventable, polymorphic: true

  # self.per_page = 1

  scope :eager_loading, -> { preload(:user) }
  scope :default_order, -> { order(id: :desc) }

  before_create do
    self.user_name = user.try(:uname) || 'guest'
    self.eventable_name ||= eventable.name if eventable.respond_to?(:name)
  end
  # after_create { self.class.current_controller = nil }

  class << self
    def create_with_current_controller(attributes)
      create(attributes) do |el|
        el.user = current_controller.current_user
        el.ip = current_controller.request.remote_ip
        el.controller = current_controller.class.to_s
        el.action = current_controller.action_name
        el.protocol = 'web'
      end
    end

    def current_controller
      Thread.current[:current_controller]
    end

    def current_controller=(ctrl)
      Thread.current[:current_controller] = ctrl
    end
  end
end
