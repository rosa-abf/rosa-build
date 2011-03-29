#rails_env = ENV['RAILS_ENV'] || 'production'
worker_processes 4

preload_app true

#working_directory "/path/to/app/current" # available in 0.94.0+
listen '/tmp/rosa_build.sock', :backlog => 2048
#listen "/tmp/.sock", :backlog => 64
#listen 8080, :tcp_nopush => true
#
#nuke workers after 30 seconds instead of 60 seconds (the default)
timeout 120
#
#feel free to point this anywhere accessible on the filesystem
pid "/var/www/rosa_build/shared/pids/unicorn.pid"

#
# REE
# http://www.rubyenterpriseedition.com/faq.html#adapt_apps_for_cow
if GC.respond_to?(:copy_on_write_friendly=)
  GC.copy_on_write_friendly = true
end

# By default, the Unicorn logger will write to stderr.
# Additionally, ome applications/frameworks log to stderr or stdout,
# so prevent them from going to /dev/null when daemonized here:
stderr_path "/var/www/rosa_build/shared/log/unicorn.stderr.log"
stdout_path "/var/www/rosa_build/shared/log/unicorn.stdout.log"

# combine REE with "preload_app true" for memory savings
# http://rubyenterpriseedition.com/faq.html#adapt_apps_for_cow
preload_app true

before_fork do |server, worker|
  ##
  # When sent a USR2, Unicorn will suffix its pidfile with .oldbin and
  # immediately start loading up a new version of itself (loaded with a new
  # version of our app). When this new Unicorn is completely loaded
  # it will begin spawning workers. The first worker spawned will check to
  # see if an .oldbin pidfile exists. If so, this means we've just booted up
  # a new Unicorn and need to tell the old one that it can now die. To do so
  # we send it a QUIT.
  #
  # Using this method we get 0 downtime deploys.

  old_pid = Rails.root + '/tmp/pids/unicorn.pid.oldbin'
  if File.exists?(old_pid) && server.pid != old_pid
    begin
      Process.kill("QUIT", File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
      # someone else did our job for us
    end
  end
end


#before_fork do |server, worker|
#  # the following is highly recomended for Rails + "preload_app true"
#  # as there's no need for the master process to hold a connection
#  defined?(ActiveRecord::Base) and
#    ActiveRecord::Base.connection.disconnect!
#end

after_fork do |server, worker|
  # per-process listener ports for debugging/admin/migrations
  # addr = "127.0.0.1:#{9293 + worker.nr}"
  # server.listen(addr, :tries => -1, :delay => 5, :tcp_nopush => true)

  # the following is *required* for Rails + "preload_app true",
  defined?(ActiveRecord::Base) and
    ActiveRecord::Base.establish_connection

  # if preload_app is true, then you may also want to check and
  # restart any other shared sockets/descriptors such as Memcached,
  # and Redis.  TokyoCabinet file handles are safe to reuse
  # between any number of forked children (assuming your kernel
  # correctly implements pread()/pwrite() system calls)
  srand
end
