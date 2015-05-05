# Private: Finders of all sorts: methods to find Project records, methods to find
# other records which belong to given Project.
#
# This module gets included into Project.
module Project::Finders
  extend ActiveSupport::Concern

  included do

    scope :recent, -> { order(:name) }
    scope :search_order, -> { order('CHAR_LENGTH(projects.name) ASC') }
    scope :search, ->(q) {
      q = q.to_s.strip
      by_name("%#{q}%").search_order if q.present?
    }
    scope :by_name,       ->(name) { where('projects.name ILIKE ?', name) if name.present? }
    scope :by_owner,      ->(name) { where('projects.owner_uname ILIKE ?', "%#{name}%") if name.present? }

    scope :by_owner_and_name, ->(*params) {
      term = params.map(&:strip).join('/').downcase
      where("lower(concat(owner_uname, '/', name)) ILIKE ?", "%#{term}%") if term.present?
    }
    scope :by_visibilities, ->(v) { where(visibility: v) }
    scope :opened, -> { where(visibility: 'open') }
    scope :package, -> { where(is_package: true) }
    scope :addable_to_repository, ->(repository_id) {
      where('projects.id NOT IN (
              SELECT ptr.project_id
              FROM project_to_repositories AS ptr
              WHERE ptr.repository_id = ?)', repository_id)
    }
    scope :by_owners, ->(group_owner_ids, user_owner_ids) {
      where("(projects.owner_id in (?) AND projects.owner_type = 'Group') OR
        (projects.owner_id in (?) AND projects.owner_type = 'User')", group_owner_ids, user_owner_ids)
    }

    scope :project_aliases, ->(project)  {
      where.not(id: project.id).
        where('alias_from_id IN (:ids) OR id IN (:ids)', { ids: [project.alias_from_id, project.id].compact })
    }

    after_commit :clear_caches
    after_touch  :clear_caches
  end

  module ClassMethods

    # Public: Get cached Project record by owner and name.
    #
    # Returns Project record.
    # Raises ActiveRecord::RecordNotFound if nothing was found.
    def find_by_owner_and_name(first, last = nil)
      arr = first.try(:split, '/') || []
      arr = (arr << last).compact
      return nil if arr.length != 2
      Rails.cache.fetch(['Project.find_by_owner_and_name', arr.first, arr.last]) do
        find_by(owner_uname: arr.first, name: arr.last)
      end || by_owner_and_name(*arr).first
    end

    def find_by_owner_and_name!(first, last = nil)
      find_by_owner_and_name(first, last) or raise ActiveRecord::RecordNotFound
    end
  end

  protected

  # Private: after_commit and after_touch hook which clears find_cached cache.
  def clear_caches
    Rails.cache.delete(['Project.find_by_owner_and_name', owner_uname, name])
  end
end
