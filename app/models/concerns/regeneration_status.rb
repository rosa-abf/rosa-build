module RegenerationStatus

  def human_regeneration_status
    self.class::HUMAN_REGENERATION_STATUSES[last_regenerated_status] || :no_data
  end

  def human_status
    self.class::HUMAN_STATUSES[status] || :no_data
  end

  READY                     = 0
  WAITING_FOR_REGENERATION  = 100
  REGENERATING              = 200

  HUMAN_STATUSES = {  
    READY                     => :ready,
    WAITING_FOR_REGENERATION  => :waiting_for_regeneration,
    REGENERATING              => :regenerating
  }

  HUMAN_REGENERATION_STATUSES = {
    AbfWorker::BaseObserver::COMPLETED  => :completed,
    AbfWorker::BaseObserver::FAILED     => :failed,
    AbfWorker::BaseObserver::CANCELED   => :canceled
  }.freeze

end