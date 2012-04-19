namespace :db do
  desc "Drop, create, migrate then seed the database"
  task :reset_db => :environment do
    Rake::Task['db:drop'].invoke
    Rake::Task['db:create'].invoke
    Rake::Task['db:migrate'].invoke
    Rake::Task['db:fixtures:load'].invoke
    Rake::Task['db:seed'].invoke
  end
end

