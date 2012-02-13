class WriteGitHookToProjects < ActiveRecord::Migration
  def self.up
    origin_hook = File.join(::Rails.root.to_s, 'lib', 'post-receive-hook')
    Project.all.each do |project|
      hook_file = File.join(project.path, 'hooks', 'post-receive')
      FileUtils.cp(origin_hook, hook_file)
    end
  end

  def self.down
    Project.all.each { |project| FileUtils.rm_rf File.join(project.path, 'hooks', 'post-receive')}
  end
end
