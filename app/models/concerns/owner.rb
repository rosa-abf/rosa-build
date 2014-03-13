module Owner
  extend ActiveSupport::Concern

  included do
    validates :owner, presence: true
    after_create do
      relations.create({ actor_id: owner.id, actor_type: owner.class.to_s, role: 'admin' }, without_protection: true)
    end
  end
end
