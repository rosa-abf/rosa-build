require 'digest/md5'

TEST_USERS = 
  [
    ['yaroslav@markin.net'        , 'Yaroslav Markin']  ,
    ['timothy.tsvetkov@gmail.com' , 'Timothy Tsvetkov'] ,
    ['alexey.nayden@gmail.com'    , 'Alexey Nayden']
  ]

TEST_USERS.each do |tuser|
  email = tuser[0]
  next if User.find_by_email(email)
  name = tuser[1]
  pass = Digest::MD5.hexdigest(name)[0..6]
  User.create! :name => name, :email => email, :password => pass, :password_confirmation => pass
  puts "Created user #{name} (#{email}) and password #{pass}"
end
