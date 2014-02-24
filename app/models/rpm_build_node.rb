require 'ohm'
require 'ohm/expire'

class RpmBuildNode < Ohm::Model
  include Ohm::Expire

  TTL = 120

  expire TTL

  attribute :user_id
  attribute :worker_count
  attribute :busy_workers
  attribute :system

  def user
    User.where(id: user_id).first
  end

  def self.total_statistics
    systems, others, busy = 0, 0, 0
    RpmBuildNode.all.select{ |n| n.user_id }.each do |n|
      if n.system == 'true'
        systems += n.worker_count.to_i
      else
        others += n.worker_count.to_i
      end
      busy += n.busy_workers.to_i
    end
    { systems: systems, others: others, busy: busy }
  end

end