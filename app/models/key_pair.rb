class KeyPair < ActiveRecord::Base
  belongs_to :repository
  belongs_to :user

  attr_accessor :secret
  attr_accessible :public, :secret, :repository_id

  validates :repository_id, :public, :user_id, :presence => true
  validates :secret, :presence => true, :on => :create

  validates :repository_id, :uniqueness => {:message => I18n.t("activerecord.errors.key_pair.repo_key_exists")}

  before_create   :key_create_call
  before_destroy  :rm_key_call

  protected

    def key_create_call
      result, self.key_id = BuildServer.import_gpg_key_pair(public, secret)
      raise "Failed to create key_pairs for repository #{repository_id} with code #{result}." if result == 4
      if result != 0 || self.key_id.nil?
        errors.add(:public, I18n.t("activerecord.errors.key_pair.rpc_error_#{result}"))
        return false
      end
      result = BuildServer.set_repository_key(repository.platform.name, repository.name, self.key_id)
      raise "Failed to sign repository #{repository.name} in platform #{repository.platform.name}
             using key_id #{self.key_id} with code #{result}." unless result.zero?
    end

    def rm_key_call
      result = BuildServer.rm_repository_key(repository.platform.name, repository.name)
      raise "Failed to desroy repository key #{repository.name} in platform 
             #{repository.platform.name} with code #{result}." unless result.zero?
    end
end
