namespace :rights do

  desc "Generate rights from site"
  task :generate => :environment do
    Dir.glob('app/controllers/*.rb') do |file|
      require file
    end

    clist = ApplicationController.descendants
    hash = clist.inject({}) do |h, cont|
      tmp = (cont.public_instance_methods - ApplicationController.public_instance_methods).reject{|n| n.first == '_'}
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
