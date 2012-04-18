class PullRequest < Issue
  extend StateMachine::MacroMethods # no method state_machine WTF?!
  serialize :data
  #TODO add validates to serialized data
  scope :needed_checking, where(:state => ['open', 'blocked', 'ready'])

  state_machine :initial => :open do
    #after_transition [:ready, :blocked] => [:merged, :closed] do |pull, transition|
    #  FileUtils.rm_rf(pull.path) # What about diff?
    #end

    event :ready do
      transition [:open, :blocked] => :ready
    end

    event :block do
      transition [:open, :ready] => :block
    end

    event :merging do
      transition :ready => :merged
    end

    event :close do
      transition [:open, :ready, :blocked] => :closed
    end

    event :reopen do
      transition :closed => :open
    end
  end

  def can_merge?
    state == 'ready'
  end

  def check
    if ret = merge
      system("cd #{path} && git reset --hard HEAD^") # remove merge commit
      ready
    else
      system("cd #{path} && git reset --hard HEAD")
      block
    end
  end

  def merge!(who)
    return false unless can_merge?
    Dir.chdir(path) do
      system "git config user.name \"#{who.uname}\" && git config user.email \"#{who.email}\""
      if merge
        merging
        system("git push origin HEAD")
      end
    end
  end

  protected

  def path
    filename = [id, project.owner.uname, project.name].join('-')
    if Rails.env == "production"
      File.join('/srv/rosa_build/shared/tmp', "pull_requests", filename)
    else
      File.join(Rails.root, "tmp", Rails.env, "pull_requests", filename)
    end
  end

  def merge
    clone
    system("cd #{path} && git checkout #{data[:base_branch]} && git merge --no-ff #{data[:head_branch]}")
  end

  def clone
    git = Grit::Git.new(path)

    unless git.exist?
      FileUtils.mkdir_p(path)
      Dir.chdir(path) do
        system("git clone --local --no-hardlinks #{project.path} #{path}")
      end
    else
      Dir.chdir(path) do
        [data[:base_branch], data[:head_branch]].each do |branch|
          system "git checkout #{branch} && git pull origin #{branch}"
        end
      end
    end
    # TODO catch errors
  end

  def set_serial_id
    self.update_attribute :serial_id, self.project.pull_requests.count
  end
end
