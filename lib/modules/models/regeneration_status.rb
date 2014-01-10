module Modules
  module Models
    module RegenerationStatus
      extend ActiveSupport::Concern

      READY                     = 0
      WAITING_FOR_REGENERATION  = 100
      REGENERATING              = 200

      HUMAN_STATUSES = {
        READY                     => :ready,
        WAITING_FOR_REGENERATION  => :waiting_for_regeneration,
        REGENERATING              => :regenerating
      }

      HUMAN_REGENERATION_STATUSES = {
        AbfWorker::BaseObserver::COMPLETED  => :completed,
        AbfWorker::BaseObserver::FAILED     => :failed,
        AbfWorker::BaseObserver::CANCELED   => :canceled
      }.freeze

      included do
        after_update :cleanup_file_store

        def sha1_of_file_store_files
          files = []
          files << last_regenerated_log_sha1 if last_regenerated_log_sha1.present?
          files
        end

        def human_regeneration_status
          self.class::HUMAN_REGENERATION_STATUSES[last_regenerated_status] || :no_data
        end

        def human_status
          self.class::HUMAN_STATUSES[status] || :no_data
        end

        def cleanup_file_store
          old_log_sha1 = last_regenerated_log_sha1_was
          if old_log_sha1.present? && old_log_sha1 != last_regenerated_log_sha1
            later_destroy_files_from_file_store([old_log_sha1])
          end
        end
      end
    end
  end
end