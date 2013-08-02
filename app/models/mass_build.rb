class MassBuild < ActiveRecord::Base
  belongs_to :build_for_platform, :class_name => 'Platform', :conditions => {:platform_type => 'main'}
  belongs_to :save_to_platform, :class_name => 'Platform'
  belongs_to :user
  has_many :build_lists, :dependent => :destroy

  serialize :extra_repositories,  Array
  serialize :extra_build_lists,   Array

  scope :recent, order("#{table_name}.created_at DESC")
  scope :by_platform, lambda { |platform| where(:save_to_platform_id => platform.id) }
  scope :outdated, where("#{table_name}.created_at < ?", Time.now + 1.day - BuildList::MAX_LIVE_TIME)

  attr_accessor :arches
  attr_accessible :arches, :auto_publish, :projects_list, :build_for_platform_id,
                  :extra_repositories, :extra_build_lists

  validates :save_to_platform_id, :build_for_platform_id, :arch_names, :name, :user_id, :presence => true
  validates :projects_list, :length => {:maximum => 500_000}, :presence => true
  validates_inclusion_of :auto_publish, :in => [true, false]

  after_commit      :build_all, :on => :create
  before_validation :set_data,  :on => :create

  COUNT_STATUSES = [
    :build_lists,
    :build_published,
    :build_pending,
    :build_started,
    :build_publish,
    :build_error,
    :success,
    :build_canceled
  ]

  def build_all
    # later with resque
    arches_list = arch_names ? Arch.where(:name => arch_names.split(', ')) : Arch.all
    auto_publish ||= false

    projects_list.lines.each do |name|
      next if name.blank?
      name.chomp!; name.strip!

      if project = Project.joins(:repositories).where('repositories.id in (?)', save_to_platform.repository_ids).find_by_name(name)
        begin
          return if self.reload.stop_build
          arches_list.each do |arch|
            rep_id = (project.repository_ids & save_to_platform.repository_ids).first
            project.build_for(build_for_platform, save_to_platform, rep_id, user, arch, auto_publish, self, 0)
          end
        rescue RuntimeError, Exception
        end
      else
        MassBuild.increment_counter :missed_projects_count, id
        list = (missed_projects_list || '') << "#{name}\n"
        update_column :missed_projects_list, list
      end
    end
  end
  later :build_all, :queue => :clone_build

  def generate_failed_builds_list
    report = ""
    BuildList.select('build_lists.id, projects.name as project_name, arches.name as arch_name').
    where(
      :status => BuildList::BUILD_ERROR,
      :mass_build_id => self.id
    ).joins(:project, :arch).find_in_batches(:batch_size => 100) do |build_lists|
      build_lists.each do |build_list|
        report << "ID: #{build_list.id}; "
        report << "PROJECT_NAME: #{build_list.project_name}; "
        report << "ARCH: #{build_list.arch_name}\n"
      end
    end
    report
  end

  def cancel_all
    update_column(:stop_build, true)
    build_lists.find_each(:batch_size => 100) do |bl|
      bl.cancel
    end
  end
  later :cancel_all, :queue => :clone_build

  def publish_success_builds(user)
    publish user, BuildList::SUCCESS, BuildList::FAILED_PUBLISH
  end
  later :publish_success_builds, :queue => :clone_build

  def publish_test_failed_builds(user)
    publish user, BuildList::TESTS_FAILED
  end
  later :publish_test_failed_builds, :queue => :clone_build

  private

  def publish(user, *statuses)
    builds = build_lists.where(:status => statuses)
    builds.update_all(:publisher_id => user.id)
    builds.order(:id).find_in_batches(:batch_size => 50) do |bls|
      bls.each{ |bl| bl.can_publish? && bl.now_publish }
    end
  end

  def set_data
    if save_to_platform
      self.name = "#{Time.now.utc.to_date.strftime("%d.%b")}-#{save_to_platform.name}"
      self.build_for_platform = save_to_platform if save_to_platform.main?
    end
    self.arch_names = Arch.where(:id => arches).map(&:name).join(", ")

    self.projects_list = projects_list.lines.map do |name|
      name.chomp.strip if name.present?
    end.compact.uniq.join("\r\n") if projects_list.present?
  end
end
