class BuildList < ActiveRecord::Base
  belongs_to :project
  belongs_to :arch
  has_many :items, :class_name => "BuildList::Item", :dependent => :destroy

  validates :project_id, :presence => true
  validates :branch_name, :presence => true

  BUILD_PENDING = 2
  BUILD_STARTED = 3

  STATUSES = [BuildServer::SUCCESS, BUILD_PENDING, BUILD_STARTED, BuildServer::BUILD_ERROR]
  HUMAN_STATUSES = { BuildServer::BUILD_ERROR => :build_error,
                     BUILD_PENDING => :build_pending,
                     BUILD_STARTED => :build_started,
                     BuildServer::SUCCESS => :success
                    }

  scope :recent, order("created_at DESC")
  scope :current, lambda { where(["status in (?) OR (status in (?) AND notified_at >= ?)", [BUILD_PENDING, BUILD_STARTED], [BuildServer::SUCCESS, BuildServer::ERROR], Time.now - 2.days]) }
  scope :for_status, lambda {|status| where(:status => status) }
  scope :scoped_to_arch, lambda {|arch| where(:arch_id => arch) }
  scope :scoped_to_branch, lambda {|branch| where(:branch_name => branch) }
  scope :scoped_to_is_circle, lambda {|is_circle| where(:is_circle => is_circle) }
  scope :for_creation_date_period, lambda{|start_date, end_date|
    if start_date && end_date
      where(["created_at BETWEEN ? AND ?", start_date, end_date])
    elsif start_date && !end_date
      where(["created_at >= ?", start_date])
    elsif !start_date && end_date
      where(["created_at <= ?", end_date])
    end
  }
  scope :for_notified_date_period, lambda{|start_date, end_date|
    if start_date && end_date
      where(["notified_at BETWEEN ? AND ?", start_date, end_date])
    elsif start_date && !end_date
      where(["notified_at >= ?", start_date])
    elsif !start_date && end_date
      where(["notified_at <= ?", end_date])
    end
  }

  serialize :additional_repos

  def self.human_status(status)
    I18n.t("layout.build_lists.statuses.#{HUMAN_STATUSES[status]}")
  end

  def human_status
    self.class.human_status(status)
  end

  def set_items(items_hash)
    self.items = []

    items_hash.each do |level, items|
      items.each do |item|
        self.items << self.items.build(:name => item, :level => level.to_i)
      end
    end
  end

end