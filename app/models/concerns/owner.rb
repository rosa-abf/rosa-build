module Owner
  extend ActiveSupport::Concern

  included do
    validates :owner, presence: true
    after_create do
      relations.create(actor: owner, role: 'admin')
    end
  end
end
