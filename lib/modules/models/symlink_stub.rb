# -*- encoding : utf-8 -*-
module Modules
  module Models
    module SymlinkStub
      extend ActiveSupport::Concern

      included do
        def create_directory
          true
        end

        def symlink_directory
          true
        end

        def remove_symlink_directory
          true
        end
      end

      module ClassMethods
      end
    end
  end
end
