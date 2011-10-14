every 1.day, :at => '0:05 am' do
  runner "Download.rotate_nginx_log"
end

every 1.day, :at => '0:10 am' do
  runner "Download.parse_and_remove_nginx_log"
end
