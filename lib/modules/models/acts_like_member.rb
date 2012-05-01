# -*- encoding : utf-8 -*-
module Modules
  module Models
    module ActsLikeMember
      extend ActiveSupport::Concern

      included do |klass|
        scope :not_member_of, lambda { |item|
          where("
            #{klass.table_name}.id NOT IN (
              SELECT relations.actor_id
              FROM relations
              WHERE (
                relations.actor_type = '#{klass.to_s}'
                AND relations.target_type = '#{item.class.to_s}'
                AND relations.target_id = #{item.id}
              )
            )
          ")
        }

        scope :search_order, order("CHAR_LENGTH(uname) ASC")
        scope :without, lambda {|a| where("#{klass.table_name}.id NOT IN (?)", a)}
        scope :search, lambda {|q| where("#{klass.table_name}.uname ILIKE ?", "%#{q.to_s.strip}%")}

      end

      module ClassMethods
      end
    end
  end
end

