module Modules
  module Models
    module PersonalRepository
      extend ActiveSupport::Concern

      included do
        after_create :create_personal_repository, :unless => :system?
      end

      def create_personal_repository
        begin
          pl = own_platforms.build
          pl.owner = self
          pl.name = "#{self.uname}_personal"
          pl.description = "#{self.uname}_personal"
          pl.platform_type = 'personal'
          pl.distrib_type = APP_CONFIG['distr_types'].first
          pl.visibility = 'open'
          pl.save!

          rep = pl.repositories.build
          rep.name = 'main'
          rep.description = 'main'
          rep.save!
        rescue Exception => e
          pl.now_destroy rescue false
          raise e
        end
        return true
      end

      def personal_platform
        own_platforms.personal.first
      end

      def personal_repository
        personal_platform.repositories.first
      end

      module ClassMethods
      end
    end
  end
end
