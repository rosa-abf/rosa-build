module Modules
  module Models
    module ActsLikeMember
      extend ActiveSupport::Concern

      included do
        scope :not_member_of, -> {|item|
          where("
            #{table_name}.id NOT IN (
              SELECT relations.actor_id
              FROM relations
              WHERE (
                relations.actor_type = '#{self.to_s}'
                AND relations.target_type = '#{item.class.to_s}'
                AND relations.target_id = #{item.id}
              )
            )
          ")
        }
        scope :search_order,   { order('CHAR_LENGTH(#{table_name}.uname) ASC') }
        scope :without,  ->(a) { where("#{table_name}.id NOT IN (?)", a) }
        scope :by_uname, ->(n) { where("#{table_name}.uname ILIKE ?", n) }
        scope :search,   ->(q) { by_uname("%#{q.to_s.strip}%") }
      end

      def to_param
        uname
      end

      module ClassMethods
        def find_by_insensitive_uname(uname)
          find_by_uname(uname) || by_uname(uname).first
        end

        def find_by_insensitive_uname!(uname)
          find_by_insensitive_uname(uname) or raise ActiveRecord::RecordNotFound
        end
      end
    end
  end
end

