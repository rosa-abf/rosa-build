require 'gitolito'

Grit::Git.git_timeout = 60
# Grit::Git.git_max_size = 20.megabytes

class Object
  def with_ga(&block)
    ::Gitolito::GitoliteAdmin.thread_safe(File.join(APP_CONFIG['root_path'], 'gitolite-admin'), {:wait_lock => true, :seconds => 60}) do |ga|
      block.call(ga)
    end
    # ga = Gitolito::GitoliteAdmin.new File.join(APP_CONFIG['root_path'], 'gitolite-admin'); block.call(ga)
  end
end
