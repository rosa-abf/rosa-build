namespace :assets do
  desc 'Copy assets for error pages'
  task build: :environment do
    puts "Copy assets for error pages"
    src_name = "application"
    trg_name = "new_application"
    trg_dir = File.join("public", "assets")
    ["css", "js"].each do |ext|
      trg_path = File.join(trg_dir, "#{trg_name}.#{ext}")
      src_path = File.join("..", ActionController::Base.helpers.asset_pack_path("#{src_name}.#{ext}"))
      FileUtils.rm_f(trg_path)
      FileUtils.ln_s(src_path, trg_path)
    end
  end
end

