class NodeInstruction < ActiveRecord::Base
  STATUSES = [
    DISABLED    = 'disabled',
    READY       = 'ready',
    RESTARTING  = 'restarting',
    FAILED      = 'failed'
  ]

  belongs_to :user

  attr_encrypted :instruction, key: APP_CONFIG['keys']['node_instruction_secret_key']

  validates :user,        presence: true
  validates :instruction, presence: true, length: { maximum: 10000 }
  validates :status,      presence: true
  validate  -> {
    errors.add(:status, 'Can be only single active instruction for each node') if !disabled? && NodeInstruction.where('id != ?', id.to_i).where(user_id: user_id, status: STATUSES - [DISABLED]).exists?
  }

  attr_accessible :instruction, :user_id, :output, :status

  state_machine :status, initial: :ready do
    event :ready do
      transition %i(ready restarting disabled failed) => :ready
    end

    event :disable do
      transition ready: :disabled
    end

    event :restart do
      transition ready: :restarting
    end

    event :fail do
      transition restarting: :failed
    end
  end

end
