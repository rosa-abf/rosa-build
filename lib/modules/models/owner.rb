# -*- encoding : utf-8 -*-
module Modules
  module Models
    module Owner
      extend ActiveSupport::Concern

      included do
          belongs_to :owner_user, :class_name => 'User', :foreign_key => 'owner_id'
          belongs_to :owner_group, :class_name => 'Group', :foreign_key => 'owner_id'

        after_create lambda { relations.create :actor_id => owner.id, :actor_type => owner.class.to_s, :role => 'admin' }
      end

      def name_with_owner
        o = owner_type == 'User' ? owner_user : owner_group
        "#{o.respond_to?(:uname) ? o.uname : o.name}/#{self.name}"
      end
    end
  end
end
