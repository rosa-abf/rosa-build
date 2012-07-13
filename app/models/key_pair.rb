class KeyPair < ActiveRecord::Base
  belongs_to :repository
  belongs_to :user

  attr_accessor :secret
  attr_accessible :public, :secret, :repository_id

  after_create :key_create_call

  def key_create_call
    code, self.key_id = BuildServer.import_gpg_key_pair(public, secret)
    if code.zero?
      set_code = BuildServer.set_repository_key(repository_id, repository.platform_id, key_id)
      if set_code.zero?
        self.save
      else
        set_code
      end
    else
      code
    end
  end

  def rm_key_call
    if BuildServer.rm_repository_key(repository.platform_id, repository_id) == 0
      self.destroy
      return true
    end

    false
  end
end
