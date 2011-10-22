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

CATEGORIES = {
  :mandriva => 
  %(Accessibility
Archiving/Backup
Archiving/Cd burning
Archiving/Compression
Archiving/Other
Books/Computer books
Books/Faqs
Books/Howtos
Books/Literature
Books/Other
Communications
Databases
Development/C
Development/C++
Development/Databases
Development/GNOME and GTK+
Development/Java
Development/KDE and Qt
Development/Kernel
Development/Other
Development/Perl
Development/PHP
Development/Python
Development/Ruby
Development/X11
Editors
Education
Emulators
File tools
Games/Adventure
Games/Arcade
Games/Boards
Games/Cards
Games/Other
Games/Puzzles
Games/Sports
Games/Strategy
Graphical desktop/Enlightenment
Graphical desktop/FVWM based
Graphical desktop/GNOME
Graphical desktop/Icewm
Graphical desktop/KDE
Graphical desktop/Other
Graphical desktop/Sawfish
Graphical desktop/WindowMaker
Graphical desktop/Xfce
Graphics
Monitoring
Networking/Chat
Networking/File transfer
Networking/Instant messaging
Networking/IRC
Networking/Mail
Networking/News
Networking/Other
Networking/Remote access
Networking/WWW
Office
Publishing
Sciences/Astronomy
Sciences/Biology
Sciences/Chemistry
Sciences/Computer science
Sciences/Geosciences
Sciences/Mathematics
Sciences/Other
Sciences/Physics
Shells
Sound
System/Base
System/Cluster
System/Configuration/Boot and Init
System/Configuration/Hardware
System/Configuration/Networking
System/Configuration/Other
System/Configuration/Packaging
System/Configuration/Printing
System/Fonts/Console
System/Fonts/True type
System/Fonts/Type1
System/Fonts/X11 bitmap
System/Internationalization
System/Kernel and hardware
System/Libraries
System/Printing
System/Servers
System/X11
Terminals
Text tools
Toys
Video),
  :naulinux =>
%(Amusements/Games
Amusements/Graphics
Applications/Archiving
Applications/Communications
Applications/Databases
Applications/Editors
Applications/Emulators
Applications/Engineering
Applications/File
Applications/Internet
Applications/Multimedia
Applications/Productivity
Applications/Publishing
Applications/System
Applications/Text
Development/Debuggers
Development/Languages
Development/Libraries
Development/System
Development/Tools
Documentation
System Environment/Base
System Environment/Daemons
System Environment/Kernel
System Environment/Libraries
System Environment/Shells
User Interface/Desktops
User Interface/X
User Interface/X Hardware Support)
}

CATEGORIES.each do |platform_type, categories|
  parent = Category.roots.find_or_create_by_name(platform_type)
  categories.split("\n").each do |category|
    Category.find_or_create_by_name(category) do |c|
      c.parent = parent
    end
  end
end
