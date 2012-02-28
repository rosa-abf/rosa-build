require 'highline/import'

desc "Add branch for platform projects"
task :add_branch => :environment do
  src_branch = ENV['SRC_BRANCH'] || 'import_mandriva2011'
  dst_branch = ENV['DST_BRANCH'] || 'rosa2012lts'

  say "START add branch #{dst_branch} from #{src_branch}"
  Platform.find_by_name(dst_branch).repositories.each do |r|
    say "=== Process #{r.name} repo"
    r.projects.find_each do |p|
      say "===== Process #{p.name} project"
      tmp_path = Rails.root.join('tmp', p.name)
      system("git clone #{p.path} #{tmp_path}")
      system("cd #{tmp_path} && git checkout remotes/origin/#{src_branch}") or system("cd #{tmp_path} && git checkout master")
      system("cd #{tmp_path} && git checkout -b #{dst_branch}")
      system("cd #{tmp_path} && git push origin HEAD")
      FileUtils.rm_rf tmp_path
    end
  end
  say 'DONE'
end
