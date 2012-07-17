class KeyPair < ActiveRecord::Base
  belongs_to :repository
  belongs_to :user

  attr_accessor :secret
  attr_accessible :public, :secret, :repository_id

  after_create :key_create_call

  def key_create_call
    if KeyPair.exists? :repository_id => self.repository_id
      errors.add(:repository_id, I18n.t('flash.key_pairs.key_exists'))
      return false
    end

    code, self.key_id = BuildServer.import_gpg_key_pair(public, secret)
    if code.zero?
      set_code = BuildServer.set_repository_key(repository_id, repository.platform_id, key_id)
      set_code.zero? ? self.save : set_code
    else
      code
    end
  end

  def rm_key_call
    return self.destroy if BuildServer.rm_repository_key(repository.platform_id, repository_id) == 0
    false
  end
end
