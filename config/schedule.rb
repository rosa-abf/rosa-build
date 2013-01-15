# -*- encoding : utf-8 -*-
#every 1.day, :at => '0:05 am' do
#  runner "Download.rotate_nginx_log"
#end
#
#every 1.day, :at => '0:10 am' do
#  runner "Download.parse_and_remove_nginx_log"
#end

every 1.day, :at => '4:00 am' do
  rake "import:sync:all", :output => 'log/sync.log'
end

every 1.day, :at => '3:50 am' do
  rake "buildlist:clear:outdated", :output => 'log/build_list_clear.log'
end

every 1.day, :at => '3:30 am' do
  rake "pull_requests:clear", :output => 'log/pull_requests_clear.log'
end

every 1.day, :at => '3:00 am' do
  rake "activity_feeds:clear", :output => 'log/activity_feeds.log'
end

every 3.minute do
  runner 'AbfWorker::BuildListsPublishTaskManager.new.run', :output => 'log/task_manager.log'
end