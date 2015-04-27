require 'open3'
class KeyPair < ActiveRecord::Base
  belongs_to :repository
  belongs_to :user

  attr_accessor :fingerprint
  # attr_accessible :public, :secret, :repository_id
  attr_encrypted :secret, key: APP_CONFIG['keys']['key_pair_secret_key']

  validates :repository, :user, presence: true
  validates :secret, :public, presence: true, length: { maximum: 10000 }, on: :create

  validates :repository_id, uniqueness: { message: I18n.t("activerecord.errors.key_pair.repo_key_exists") }
  validate :check_keys

  before_create { |record| record.key_id = @fingerprint }
  after_create  { |record| record.repository.resign }

  protected

    def check_keys
      dir = Dir.mktmpdir 'keys-', APP_CONFIG['tmpfs_path']
      begin
        %w(pubring secring).each do |kind|
          filename = "#{dir}/#{kind}"
          open("#{filename}.txt", "w") { |f| f.write self.send(kind == 'pubring' ? :public : :secret) }
          system "gpg --homedir #{dir} --dearmor < #{filename}.txt > #{filename}.gpg"
        end

        public_key = get_info_of_key "#{dir}/pubring.gpg"
        secret_key = get_info_of_key "#{dir}/secring.gpg"

        if correct_key?(public_key, :public) & correct_key?(secret_key, :secret)
          if public_key[:fingerprint] != secret_key[:fingerprint]
            errors.add :secret, I18n.t('activerecord.errors.key_pair.wrong_keys')
          else
            stdin, stdout, stderr = Open3.popen3("echo '\n\n\n\n\nsave' | LC_ALL=en gpg --command-fd 0 --homedir #{dir} --edit-key #{secret_key[:keyid]} passwd")
            output = stderr.read
            if output =~ /Invalid\spassphrase/
              errors.add :secret, I18n.t('activerecord.errors.key_pair.key_has_passphrase')
            else
              @fingerprint = secret_key[:fingerprint]
            end
          end
        end
      ensure
        # remove the directory.
        FileUtils.remove_entry_secure dir
      end
    end

    def correct_key?(info, field)
      if info.empty? || info[:type].blank? || info[:fingerprint].blank? || info[:keyid].blank?
        errors.add field, I18n.t('activerecord.errors.key_pair.wrong_key')
        return false
      else
        if info[:type] != field
          errors.add field, I18n.t("activerecord.errors.key_pair.wrong_#{field}_key")
          return false
        end
      end
      return true
    end

    def get_info_of_key(file_path)
      results = {}
      str = %x[ gpg --with-fingerprint #{file_path} | sed -n 1,2p]
      info = str.strip.split("\n")
      if info.size == 2
        results[:fingerprint] = info[1].gsub(/.*\=/, '').strip.gsub(/\s/, ':')

        results[:type] = info[0] =~ /^pub\s/ ? :public : nil
        results[:type] ||= info[0] =~ /^sec\s/ ? :secret : nil

        if keyid = info[0].match(/\/[\w]+\s/)
          results[:keyid] = keyid[0].strip[1..-1]
        end
      end
      return results
    end

end
