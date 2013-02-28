# This class is based on
# https://github.com/gitlabhq/gitlabhq/blob/15c0e58a49d623a0f8747e1d7e74364324eeb79f/app/models/key.rb

class SSHKey < ActiveRecord::Base
  SHELL_KEY_COMMAND = "sudo ~#{APP_CONFIG['shell_user']}/gitlab-shell/bin/gitlab-keys"

  belongs_to :user
  attr_accessible :key, :name

  before_validation lambda { self.key = key.strip if key.present? }
  before_validation :set_fingerprint

  validates :name, :presence => true, :length => {:maximum => 255}
  validates :key, :presence => true, :length => {:maximum => 5000}, format: { :with => /ssh-.{3} / }, uniqueness: true

  def self.manage_key(action, key_id, key_content)
    #system SHELL_KEY_COMMAND, action, key_id, key_content
    system "#{SHELL_KEY_COMMAND} #{action} #{key_id} \"#{key_content}\""
    #[SHELL_KEY_COMMAND, action, key_id, key_content].join(' ')
  end

  protected

  def set_fingerprint
    return false unless key

    file = Tempfile.new('key_file')
    begin
      file.puts key
      file.rewind
      fingerprint_output = `ssh-keygen -lf #{file.path} 2>&1` # Catch stderr.
    ensure
      file.close
      file.unlink # deletes the temp file
    end
    error_message = t('activerecord.errors.ssh_key.wrong_key')
    if $?.exitstatus != 0
      errors.add :key, error_message
    else
      self.fingerprint = fingerprint_output.split.try(:[], 1)
      errors.add(:key, error_message) if fingerprint.blank?
    end
  end
end
