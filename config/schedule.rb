#every 1.day, :at => '0:05 am' do
#  runner "Download.rotate_nginx_log"
#end
#
#every 1.day, :at => '0:10 am' do
#  runner "Download.parse_and_remove_nginx_log"
#end

#every 5.minutes do
#  runner "Download.rotate_nginx_log"
#  runner "Download.send_later :parse_and_remove_nginx_log"
#end
