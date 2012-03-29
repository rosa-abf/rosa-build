# -*- encoding : utf-8 -*-
module Modules
  module Models
    module Owner
      extend ActiveSupport::Concern

      included do
        after_create lambda { relations.create :object_id => owner.id, :object_type => owner.class.to_s, :role => 'admin' }
      end

      module ClassMethods
      end
    end
  end
end
