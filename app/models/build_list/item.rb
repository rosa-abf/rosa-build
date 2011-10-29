class BuildList::Item < ActiveRecord::Base
  belongs_to :build_list

  attr_protected :build_list_id

  STATUSES = [BuildServer::SUCCESS, BuildServer::DEPENDENCIES_FAIL, BuildServer::BUILD_ERROR]
  HUMAN_STATUSES = {
                     nil => :unknown,
                     BuildServer::DEPENDENCIES_FAIL => :dependencies_fail,
                     BuildServer::SUCCESS => :success,
                     BuildServer::BUILD_ERROR => :build_error
                    }

  scope :recent, order("level ASC, name ASC")

  def self.group_by_level
    items = scoped({}).recent

    groups = []
    current_level = -1
    items.each do |item|
      groups << [] if current_level < item.level
      groups.last << item
      current_level = item.level
    end

    groups
  end

  def self.human_status(status)
    I18n.t("layout.build_lists.items.statuses.#{HUMAN_STATUSES[status]}")
  end

  def human_status
    self.class.human_status(status)
  end
  
end
