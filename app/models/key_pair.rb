class KeyPair < ActiveRecord::Base
  belongs_to :repository
  belongs_to :user

  attr_accessor :secret
  attr_accessible :public, :secret, :repository_id

  validates :repository_id, :public, :user_id, :presence => true
  validates :secret, :presence => true, :on => :create

  validates :repository_id, :uniqueness => {:message => I18n.t("activerecord.errors.key_pairs.repo_key_exists")}

  before_create   :key_create_call
  before_destroy  :rm_key_call

  protected

    def key_create_call
      result, self.key_id = BuildServer.import_gpg_key_pair(public, secret)
      raise "Failed to create key_pairs for repository #{repository_id} with code #{result}." unless result == 4
      if result != 0 || key_id.nil?
        errors.add(:public, I18n.t("activerecord.errors.key_pairs.#{result}"))
        return false
      end
      result = BuildServer.set_repository_key(repository_id, repository.platform_id, key_id)
      raise "Failed to sign repository key #{repository_id} with code #{set_code}." unless result.zero?
    end

    def rm_key_call
      result = BuildServer.rm_repository_key(repository.platform_id, repository_id)
      raise "Failed to desroy repository key #{repository_id} with code #{result}." unless result.zero?
    end
end
