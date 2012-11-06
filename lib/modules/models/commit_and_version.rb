# -*- encoding : utf-8 -*-
module Modules
  module Models
    module CommitAndVersion
      extend ActiveSupport::Concern

      included do
        
        validate lambda {
          if project && (commit_hash.blank? || project.repo.commit(commit_hash).blank?)
            errors.add :commit_hash, I18n.t('flash.build_list.wrong_commit_hash', :commit_hash => commit_hash)
          end
        }

        before_validation :set_commit_and_version
      end

      protected

      def set_commit_and_version
        if project && project_version.present? && commit_hash.blank?
          self.commit_hash = project.repo.commits(project_version.match(/^latest_(.+)/).to_a.last ||
                        project_version).try(:first).try(:id)
        elsif project_version.blank? && commit_hash.present?
          self.project_version = commit_hash
        end
      end
    end
  end
end