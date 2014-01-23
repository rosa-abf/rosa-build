namespace :sudo_test do
  desc "Test sudo from web"
  task projects: :environment do
     system "sudo touch /root/sudo_#{Time.now.to_i}.txt"
  end
end