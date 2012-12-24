# -*- encoding : utf-8 -*-
class KeyPair < ActiveRecord::Base
  belongs_to :repository
  belongs_to :user

  attr_accessor :fingerprint
  attr_accessible :public, :secret, :repository_id
  attr_encrypted :secret, :key => APP_CONFIG['secret_key']

  validates :repository_id, :user_id, :presence => true
  validates :secret, :presence => true, :length => { :maximum => 10000 }, :on => :create
  validates :public, :presence => true, :length => { :maximum => 10000 }, :on => :create

  validates :repository_id, :uniqueness => {:message => I18n.t("activerecord.errors.key_pair.repo_key_exists")}
  validate :check_keys

  before_create :set_key_id
  after_create :resign_rpms,
    :unless => Proc.new { |key_pair| key_pair.repository.platform.personal? }

  protected

    def set_key_id
      self.key_id = @fingerprint
    end

    def resign_rpms
      platform = repository.platform
      type = platform.distrib_type
      Resque.push(
        "publish_build_list_container_#{type}_worker",
        'class' => "AbfWorker::PublishBuildListContainer#{type.capitalize}Worker",
        'args' => [{
          :id => id,
          :arch => 'x86_64',
          :distrib_type => type,
          :platform => {
            :platform_path => "#{platform.path}/repository",
            :released => platform.released
          },
          :repository => {
            :name => repository.name,
            :id => repository.id
          },
          :type => :resign,
          :save_results => false,
          :time_living => 2400 # 40 min
        }]
      )
    end

    def check_keys
      dir = Dir.mktmpdir
      begin
        open("#{dir}/pubring.txt", "w") { |f| f.write self.public }
        system "gpg --homedir #{dir} --dearmor < #{dir}/pubring.txt > #{dir}/pubring.gpg"
        open("#{dir}/secring.txt", "w") { |f| f.write self.secret }
        system "gpg --homedir #{dir} --dearmor < #{dir}/secring.txt > #{dir}/secring.gpg"

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
          errors.add field, I18n.t("activerecord.errors.key_pair.contains_#{field}_key")
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
