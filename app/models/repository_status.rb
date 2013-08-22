class RepositoryStatus < ActiveRecord::Base
  READY                     = 0
  WAITING_FOR_REGENERATION  = 100
  REGENERATING              = 200
  PUBLISH                   = 300

  HUMAN_STATUSES = {  READY                     => :ready,
                      WAITING_FOR_REGENERATION  => :waiting_for_regeneration,
                      REGENERATING              => :regenerating,
                      PUBLISH                   => :publish
                    }.freeze

  validates :repository_id, :platform_id, :presence => true
  validates :repository_id, :uniqueness => {:scope => :platform_id}

  attr_accessible :last_regenerated_at, :last_regenerated_status, :platform_id, :repository_id, :status

  state_machine :status, :initial => :ready do
    event :ready do
      transition [:regenerating, :publish] => :ready
    end

    event :regenerate do
      transition :waiting_for_regeneration => :regenerating
      transition :ready => :waiting_for_regeneration
    end

    event :publish_packages do
      transition :ready => :publish
    end

    HUMAN_STATUSES.each do |code,name|
      state name, :value => code
    end
  end

end
