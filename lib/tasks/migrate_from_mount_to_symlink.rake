namespace :downloads do

  desc "Migrate from mount to symlinks"
  task migrate: :environment do
    Platform.opened.each do |pl|
      system("sudo mv #{pl.symlink_path}/*.lst #{pl.path}")
      system("sudo umount #{pl.symlink_path}")
      system("sudo rm -Rf #{pl.symlink_path}")

      pl.symlink_directory
    end
  end

end
