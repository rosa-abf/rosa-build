# -*- encoding : utf-8 -*-
module Modules
  module Models
    module TimeLiving
      extend ActiveSupport::Concern

      included do

        validates :time_living, :numericality => {
          :only_integer => true
        }, :presence => true

        validate lambda {
          # 2 min <= time_living <= 12 hours
          if 120 > time_living.to_i || time_living.to_i > 43200
            errors.add(:time_living, I18n.t('flash.time_living.numericality_error'))
          end
        }

        before_validation :convert_time_living

        attr_accessible :time_living
      end

      protected

      def convert_time_living
        self.time_living = time_living.to_i * 60 if time_living_was.to_i != time_living.to_i
      end
    end
  end
end
