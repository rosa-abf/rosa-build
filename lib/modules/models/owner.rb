# -*- encoding : utf-8 -*-
module Modules
  module Models
    module Owner
      extend ActiveSupport::Concern

      included do
        belongs_to :owner_user, :class_name => 'User', :foreign_key => 'owner_id'
        belongs_to :owner_group, :class_name => 'Group', :foreign_key => 'owner_id'

        validates :owner, :presence => true
        after_create lambda { relations.create :actor_id => owner.id, :actor_type => owner.class.to_s, :role => 'admin' }
      end

    end
  end
end
