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
        before_create :set_last_published_commit
      end

      protected

      def set_commit_and_version
        if project && project_version.present? && commit_hash.blank?
          self.commit_hash = project.repo.commits(project_version).try(:first).try(:id)
        elsif project_version.blank? && commit_hash.present?
          self.project_version = commit_hash
        end
      end

      def set_last_published_commit
        return unless self.respond_to? :last_published_commit_hash # product?
        last_commit = self.last_published.first.try :commit_hash
        if last_commit && self.project.repo.commit(last_commit).present? # commit(nil) is not nil!
          self.last_published_commit_hash = last_commit
        end
      end
    end
  end
end
