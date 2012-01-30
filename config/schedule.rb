#every 1.day, :at => '0:05 am' do
#  runner "Download.rotate_nginx_log"
#end
#
#every 1.day, :at => '0:10 am' do
#  runner "Download.parse_and_remove_nginx_log"
#end

every 5.minutes do
  #rake "sudo_test:projects" 
  runner "Download.rotate_nginx_log"
  runner "Download.parse_and_remove_nginx_log"
end

every 1.day, :at => '4:00 am' do
  rake "import:sync:all", :output => 'log/sync.log'
end
