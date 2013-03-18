module Modules
  module Models
    module ActsLikeMember
      extend ActiveSupport::Concern

      included do
        scope :not_member_of, lambda {|item|
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
        scope :search_order, order("CHAR_LENGTH(uname) ASC")
        scope :without, lambda {|a| where("#{table_name}.id NOT IN (?)", a)}
        scope :by_uname, lambda {|n| where("#{table_name}.uname ILIKE ?", n)}
        scope :search, lambda {|q| by_uname("%#{q.to_s.strip}%")}
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

