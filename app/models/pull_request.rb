class PullRequest < Issue
  serialize :data

  state_machine :initial => :open do

    event :open do
      transition :closed => :open
      transition :blocked => :open, :if => lambda {|pull| pull.can_merge?}
    end

    event :block do
      transition :open => :blocked
    end

    event :merge do
      transition :open => :merged,  :if => lambda {|pull|  pull.can_merge?}
      transition :open => :blocked, :if => lambda {|pull| !pull.can_merge?}
    end

    event :close do
      transition [:open, :blocked] => :closed
    end
  end

  def can_merge?
    !merge
  end

  protected

  def path
    if Rails.env == "production"
      File.join('/srv/rosa_build/shared/tmp', "pull_requests", [id, project.owner.uname, project.name].join('-'))
    else
      File.join(Rails.root, "tmp", Rails.env, "pull_requests", [id, project.owner.uname, project.name].join('-'))
    end
  end

  def merge
    clone
    system "cd #{path} && git checkout #{data.base_branch} && git merge #{data.head_branch} && git reset --hard #{data.head_branch}"
  end

  def clone
    git = Git.new(path)

    unless git.exist?
      FileUtils.mkdir_p(path)
      Dir.chdir(path) do
        system("git clone --local --no-hardlinks #{project.path} #{path}")
      end
    else
      Dir.chdir(path) do
        [data.base_branch, data.head_branch].each do |branch|
          system "git checkout #{branch} && git pull origin #{branch}"
        end
      end
    end
    # TODO catch errors
  end

end
