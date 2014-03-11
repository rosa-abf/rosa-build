module Modules
  module Models
    module Owner
      extend ActiveSupport::Concern

      included do
        validates :owner, presence: true
        after_create -> { relations.create actor_id: owner.id, actor_type: owner.class.to_s, role: 'admin' }
      end

    end
  end
end
