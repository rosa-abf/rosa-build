require 'gitolito'

class Object
  def with_ga(&block)
#    Grit::Git.git_timeout = 60
#    ::Gitolito::GitoliteAdmin.thread_safe(File.join(APP_CONFIG['root_path'], 'gitolite-admin'), {:wait_lock => true, :seconds => 60}) do |ga|
#      block.call(ga)
#    end
    # ga = Gitolito::GitoliteAdmin.new File.join(APP_CONFIG['root_path'], 'gitolite-admin'); block.call(ga)
  end
end
