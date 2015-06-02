class BuildList::Item < ActiveRecord::Base

  belongs_to :build_list, touch: true

  # attr_protected :build_list_id

  GIT_ERROR = 5

  STATUSES = [BuildList::SUCCESS, BuildList::BUILD_ERROR, BuildList::BUILD_STARTED, GIT_ERROR, BuildList::BUILD_CANCELED] # BuildList::DEPENDENCIES_ERROR
  HUMAN_STATUSES = {
                     nil => :unknown,
                     GIT_ERROR => :git_error,
                     # BuildList:DEPENDENCIES_ERROR: :dependencies_error,
                     BuildList::SUCCESS        => :success,
                     BuildList::BUILD_STARTED  => :build_started,
                     BuildList::BUILD_ERROR    => :build_error,
                     BuildList::BUILD_CANCELED => :build_canceled
                    }

  scope :recent, -> { order("#{table_name}.level ASC, #{table_name}.name ASC") }

  def self.group_by_level
    groups = []
    current_level = -1
    all.recent.find_each do |item|
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
