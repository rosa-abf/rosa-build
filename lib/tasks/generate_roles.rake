namespace :roles do
  desc "Load roles from file 'config/roles.yml'"
  task :load => :environment do
    unless File.exists? File.expand_path('config/roles.yml')
      puts "File 'config/roles.yml' doesn't exists"
      return
    end

    t = YAML.load_file File.expand_path('config/roles.yml')
    unless t.is_a? Hash and t[:Roles]
      puts "File 'config/roles.yml' has wrong format"
    else
      begin
        Role.all_from_dump! t
        puts "All roles has been loaded"
      rescue
        puts "Fail with seeding db"
      end
    end
  end

  task :apply => :environment do
    models = ActiveRecord::Base.relation_acters
    models = models.inject([]) do |arr, m|
      arr << m.all.select {|rec| rec.global_role_id.nil? || rec.global_role_id == 0}
      arr
    end
    models.flatten!
    begin
      models.each do |m|
        m.method(:add_default_role).call
        m.save
      end
    rescue
      puts 'Fail to apply default roles'
      return
    end
    puts 'Default roles successfully applied.'
  end
end

namespace :rights do

  desc "Generate rights from site"
  task :generate => :environment do
    Dir.glob('app/controllers/*.rb') do |file|
      require file
    end

    clist = ApplicationController.descendants
    hash = clist.inject({}) do |h, cont|
      #tmp = (cont.public_instance_methods - ApplicationController.public_instance_methods).reject{|n| n.first == '_'}
      tmp = cont.action_methods.reject{|m| m.first == '_'}
      h[cont.controller_name] = tmp if tmp.size > 0
      h
    end

    rights = Right.all.inject([]) do |arr, r|
      arr << [r.controller, r.action]
      arr
    end

    hash.each do |key, value|
      hash[key] = value.reject {|n| rights.include? [key, n]}
    end
    hash.delete_if {|k, v| v.size == 0}

    hash.each do |controller, value|
      value.each do |action|
        r = Right.create(:controller => controller, :action => action)
        puts '"' + r.name + '" was generated'
      end
    end
    puts 'All rights was generated'
  end
end
