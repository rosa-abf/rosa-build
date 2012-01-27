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
 rake "import:sync:all" # RELEASE=official/2011 PLATFORM=mandriva2011 REPOSITORY=main
 rake "import:sync:all REPOSITORY=contrib" # RELEASE=official/2011 PLATFORM=mandriva2011
 rake "import:sync:all REPOSITORY=non-free" # RELEASE=official/2011 PLATFORM=mandriva2011
 rake "import:sync:all RELEASE=devel/cooker PLATFORM=cooker" # REPOSITORY=main
 rake "import:sync:all RELEASE=devel/cooker PLATFORM=cooker REPOSITORY=contrib"
 rake "import:sync:all RELEASE=devel/cooker PLATFORM=cooker REPOSITORY=non-free"
end
