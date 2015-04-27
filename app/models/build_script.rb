class BuildScript < ActiveRecord::Base
  include FileStoreClean

  STATUSES = [
    ACTIVE  = 'active',
    BLOCKED = 'blocked'
  ]
  FORMAT = 'tar.gz'

  belongs_to :project

  validates :treeish, presence: true
  validates :project, presence: true
  validates :project_id, uniqueness: { scope: :treeish }

  scope :by_active,   -> { where(status: ACTIVE) }
  scope :by_treeish,  -> treeish { where(treeish: treeish) }

  before_validation :attach_project
  attr_writer       :project_name
  # attr_accessible   :project_name, :treeish, :commit, :sha1, :status

  state_machine :status, initial: :active do
    event(:disable) { transition active: :blocked }
    event(:enable)  { transition blocked: :active }
  end

  def sha1_of_file_store_files
    [sha1].select(&:present?)
  end

  def project_name
    @project_name.presence || project.try(:name_with_owner)
  end

  def can_update_archive?
    last_commit != commit
  end

  def update_archive
    old_sha1, new_commit = sha1, last_commit

    archive   = project.archive_by_treeish_and_format(treeish, FORMAT)
    new_sha1  = FileStoreService::File.new(data: archive).save
    if new_sha1.present?
      update_attributes(sha1: new_sha1, commit: new_commit)
      destroy_files_from_file_store(old_sha1) if old_sha1.present?
    end
  end
  later :update_archive, queue: :middle

  protected

  def last_commit
    project.repo.commits(treeish, 1).first.try(:id)
  end

  def attach_project
    if @project_name.present?
      self.project = Project.find_by_owner_and_name(@project_name)
    end
  end

end
