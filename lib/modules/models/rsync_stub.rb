# -*- encoding : utf-8 -*-
module Modules
  module Models
    module RsyncStub
      extend ActiveSupport::Concern

      included do
        def create_directory
          true
        end

        def mount_directory_for_rsync
          true
        end

        def umount_directory_for_rsync
          true
        end
      end

      module ClassMethods
      end
    end
  end
end
