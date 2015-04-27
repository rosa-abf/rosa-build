class ProjectTag < ActiveRecord::Base
  include FileStoreClean

  FORMATS = {
    'zip'     => 0,
    'tar.gz'  => 1
  }

  belongs_to :project

  validates :project, :commit_id, :sha1, :tag_name, :format_id, presence: true
  validates :project_id, uniqueness: { scope: [:tag_name, :format_id] }

  # attr_accessible :project_id, :commit_id, :sha1, :tag_name, :format_id

  def sha1_of_file_store_files
    [sha1]
  end
end
