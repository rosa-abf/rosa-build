class BuildList::Item < ActiveRecord::Base
  belongs_to :build_list

  attr_protected :build_list_id

  STATUSES = [BuildServer::SUCCESS, BuildServer::DEPENDENCIES_FAIL, BuildServer::SRPM_NOT_FOUND, BuildServer::MOCK_NOT_FOUND]
  HUMAN_STATUSES = {
                     BuildServer::MOCK_NOT_FOUND => :mock_not_found,
                     BuildServer::DEPENDENCIES_FAIL => :dependencies_fail,
                     BuildServer::SRPM_NOT_FOUND => :srpm_not_found,
                     BuildServer::SUCCESS => :success
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