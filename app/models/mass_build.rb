class MassBuild < ActiveRecord::Base
  belongs_to :platform
  belongs_to :user
  has_many :build_lists, :dependent => :destroy

  scope :by_platform, lambda { |platform| where(:platform_id => platform.id) }
  scope :outdated, where('created_at < ?', Time.now + 1.day - BuildList::MAX_LIVE_TIME)

  attr_accessor :repositories, :arches
  attr_accessible :repositories, :arches, :auto_publish

  validates :platform_id, :arch_names, :name, :user_id, :repositories, :rep_names, :presence => true
  validates_inclusion_of :auto_publish, :in => [true, false]

  after_create :build_all
  before_validation :set_data

  COUNT_STATUSES = [
    :build_lists,
    :build_published,
    :build_pending,
    :build_started,
    :build_publish,
    :build_error
  ]

  # ATTENTION: repositories and arches must be set before calling this method!
  def build_all
    platform.build_all(
      :mass_build_id => self.id,
      :user => self.user,
      :repositories => self.repositories,
      :arches => self.arches,
      :auto_publish => self.auto_publish
    ) # later with resque
  end

  def generate_failed_builds_list
    report = ""
    BuildList.where(:status => BuildServer::BUILD_ERROR, :mass_build_id => self.id).each do |build_list|
      report << "ID: #{build_list.id}; "
      report << "PROJECT_NAME: #{build_list.project.name}\n"
    end
    report
  end

  def cancel_all
    self.stop_build = true; save(:validate => false)
    build_lists.find_each(:batch_size => 100) do |bl|
      bl.cancel
    end
  end
  later :cancel_all, :queue => :clone_build

  private

  def set_data
    if new_record?
      self.rep_names = Repository.where(:id => self.repositories).map(&:name).join(", ")
      self.name = "#{Time.now.utc.to_date.strftime("%d.%b")}-#{platform.name}"
      self.arch_names = Arch.where(:id => self.arches).map(&:name).join(", ")
    end
  end

end
