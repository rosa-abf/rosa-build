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
  user = User.create! :name => name, :email => email, :password => pass, :password_confirmation => pass
  puts "Created user #{name} (#{email}) and password #{pass}"
end


=begin
TEST_PLATFORMS = %w(cooker Mandriva2010-10 Mandriva2011.4)
TEST_PROJECTS = %w(gcc glibc mysql-dev ruby ruby1.9 mc mesa avrdude vim gvim openssh-server openssh nethack binutils build-essentials rpm rpmtools ffmpeg mkvtoolnix libogg mpg123 openbox openoffice.org)


TEST_PLATFORMS.each do |platform|
  p = Platform.find_or_create_by_name(platform)
  TEST_PROJECTS.each do |project|
    pr = Project.find_or_initialize_by_platform_id_and_name(p.id, project)
    pr.unixname = pr.name
    puts "#{project} added to #{platform}" if pr.new_record?
    pr.save!
  end
end
=end

ARCHES = %w(i586 i686 x86_64 mips powerpc)
ARCHES.each do |arch|
  Arch.find_or_create_by_name arch
end
