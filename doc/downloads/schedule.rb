every 1.day, :at => '5:00' do
  #rake "sudo_test:projects" 
  runner "Download.rotate_nginx_log"
  runner "Download.parse_and_remove_nginx_log"
end
