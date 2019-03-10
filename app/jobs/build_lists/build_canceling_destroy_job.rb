module BuildLists
  class BuildCancelingDestroyJob
    def self.perform
      BuildList.for_status(BuildList::BUILD_CANCELING).for_notified_date_period(nil, 1.hours.ago).destroy_all
    end
  end
end
