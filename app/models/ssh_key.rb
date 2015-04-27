# This class is based on
# https://github.com/gitlabhq/gitlabhq/blob/15c0e58a49d623a0f8747e1d7e74364324eeb79f/app/models/key.rb

class SshKey < ActiveRecord::Base
  SHELL_KEY_COMMAND = "sudo -i -u #{APP_CONFIG['shell_user']} ~#{APP_CONFIG['shell_user']}/gitlab-shell/bin/gitlab-keys"

  belongs_to :user
  # attr_accessible :key, :name

  before_validation -> { self.key = key.strip if key.present? }
  before_validation :set_fingerprint

  validates :name, length: { maximum: 255 }
  validates :key, length: { maximum: 5000 }, format: { with: /ssh-.{3} / } # Public key?
  validates :fingerprint, uniqueness: true, presence: { message: I18n.t('activerecord.errors.ssh_key.wrong_key') }

  after_create :add_key
  before_destroy :remove_key

  protected

  def set_fingerprint
    return false unless key

    file = Tempfile.new('key_file', '/tmp')
    filename = file.path
    begin
      file.puts key
      file.rewind
      fingerprint_output = `ssh-keygen -lf #{file.path} 2>&1` # Catch stderr.
      exitstatus = $?.exitstatus
    ensure
      file.close
      file.unlink # deletes the temp file
    end
    if exitstatus != 0
      self.fingerprint = nil
    else
      self.fingerprint = fingerprint_output.split.try :[], 1
      if name.blank?
        s = fingerprint_output.split.try :[], 2
        if filename == s # no identificator
          start = key =~ /ssh-.{3} /
          self.name = key[start..start+26] # taken first 26 characters
        else
          self.name = s
        end
      end
    end
  end

  def key_id
    "key-#{id}"
  end

  def add_key
    system "#{SHELL_KEY_COMMAND} add-key #{key_id} \"#{key}\"" # Safety?
  end

  def remove_key
    system "#{SHELL_KEY_COMMAND} rm-key #{key_id}"# \"#{key}\""
  end

end
