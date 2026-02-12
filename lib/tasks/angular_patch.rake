namespace :angular do
  desc 'Patch angular.js'
  task patch: :environment do
    puts "Patch angular.js"
    file = File.join("node_modules", "angular", "angular.js")
    text = File.read(file)
    text = text.gsub(/^(\ +)blockNodes\.push\(node\);$/, "#{$1}baseExtend(blockNodes, node);")
    File.write(file, text)
  end
end

