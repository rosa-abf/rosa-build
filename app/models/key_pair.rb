class KeyPair < ActiveRecord::Base
  belongs_to :repository
  belongs_to :user

  attr_accessor :fingerprint
  attr_accessible :public, :secret, :repository_id
  attr_encrypted :secret, :key => APP_CONFIG['secret_key']

  validates :repository_id, :public, :user_id, :presence => true
  validates :secret, :presence => true, :on => :create

  validates :repository_id, :uniqueness => {:message => I18n.t("activerecord.errors.key_pair.repo_key_exists")}
  validate :check_keys

  before_create :set_key_id

  protected

    def set_key_id
      self.key_id = @fingerprint
    end

    def check_keys
      p_key_fingerprint = fingerprint_of_key(:public)
      s_key_fingerprint = fingerprint_of_key(:secret)
      if p_key_fingerprint && s_key_fingerprint
        if p_key_fingerprint != s_key_fingerprint
          errors.add :secret, I18n.t('activerecord.errors.key_pair.rpc_error_3')
        else
          @fingerprint = p_key_fingerprint
        end
      end
    end

    def fingerprint_of_key(field)
      key = self.send(field)
      tmp_file = "key-#{repository_id}-#{user_id}"
      file = Tempfile.new tmp_file
      file.write key
      file.close
      str = %x[ gpg --with-fingerprint #{file.path} | sed -n 1,2p]
      info = str.strip.split("\n")
      if info.size != 2 || (fingerprint = info[1].gsub(/.*\=/, '').strip.gsub(/\s/, ':') && fingerprint.present?)
        errors.add field, I18n.t('activerecord.errors.key_pair.wrong_key')
        return nil
      end
      prefix = field == :public ? 'pub' : 'sec'
      if info[0] !~ /^#{prefix}/
        errors.add field, I18n.t("activerecord.errors.key_pair.contains_#{field}_key")
        return nil
      end
      return fingerprint
    ensure
      if file
        file.close
        file.unlink   # deletes the temp file
      end
    end

end
