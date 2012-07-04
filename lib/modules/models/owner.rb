# -*- encoding : utf-8 -*-
module Modules
  module Models
    module Owner
      extend ActiveSupport::Concern

      included do
        after_create lambda { relations.create :actor_id => owner.id, :actor_type => owner.class.to_s, :role => 'admin' }
      end

      module ClassMethods
      end

      module InstanceMethods

        def name_with_owner
          "#{owner.uname}/#{self.name}"
        end

      end
    end
  end
end
