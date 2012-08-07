class PullRequest < ActiveRecord::Base
  STATUSES = %w(ready already blocked merged closed)
  belongs_to :issue, :autosave => true, :dependent => :destroy, :touch => true, :validate => true
  belongs_to :base_project, :class_name => 'Project', :foreign_key => 'base_project_id'
  belongs_to :head_project, :class_name => 'Project', :foreign_key => 'head_project_id'
  delegate :user, :user_id, :title, :body, :serial_id, :assignee, :status, :to_param,
    :created_at, :updated_at, :comments, :to => :issue, :allow_nil => true

  validate :uniq_merge, :on => :save
  validates_each :head_ref, :base_ref do |record, attr, value|
    check_ref record, attr, value
  end

  before_create :clean_dir
  after_destroy :clean_dir

  accepts_nested_attributes_for :issue
  attr_accessible :issue_attributes, :base_ref, :head_ref

  scope :needed_checking, includes(:issue).where(:issues => {:status => ['open', 'blocked', 'ready']})

  state_machine :status, :initial => :open do
    #after_transition [:ready, :blocked] => [:merged, :closed] do |pull, transition|
    #  FileUtils.rm_rf(pull.path) # What about diff?
    #end

    event :ready do
      transition [:ready, :open, :blocked] => :ready
    end

    event :already do
      transition [:ready, :open, :blocked] => :already
    end

    event :block do
      transition [:ready, :open, :blocked] => :blocked
    end

    event :merging do
      transition :ready => :merged
    end

    event :close do
      transition [:ready, :open, :blocked] => :closed
    end

    event :reopen do
      transition :closed => :open
    end
  end

  def status=(value)
    issue.status = value
  end

  def check(do_transaction = true)
    new_status = case merge
                 when /Already up-to-date/
                   'already'
                 when /Merge made by the 'recursive' strategy/
                   system("cd #{path} && git reset --hard HEAD^") # remove merge commit
                   'ready'
                 when /Automatic merge failed/
                   system("cd #{path} && git reset --hard HEAD") # clean git index
                   'block'
                 else
                   raise ret
                 end

    if do_transaction
      if new_status == 'already'
        ready; merging
      else
        send(new_status)
      end
    else
      self.status = new_status == 'block' ? 'blocked' : new_status
    end
  end

  def merge!(who)
    return false unless can_merging?
    Dir.chdir(path) do
      system "git config user.name \"#{who.uname}\" && git config user.email \"#{who.email}\""
      if merge
        system("git push origin HEAD")
        system("git reset --hard HEAD^") # for diff maybe FIXME
        set_user_and_time who
        merging
      end
    end
  end

  def self.default_base_project(project)
    project.is_root? ? project : project.root
  end

  def path
    filename = [id, head_project.owner.uname, head_project.name].compact.join('-')
    File.join(APP_CONFIG['root_path'], 'pull_requests', base_project.owner.uname, base_project.name, filename)
  end

  def head_branch
    if base_project != head_project
      "head_#{head_ref}"
    else
      head_ref
    end
  end

  def common_ancestor
    return @common_ancestor if @common_ancestor
    repo = Grit::Repo.new(path)
    base_commit = repo.commits(base_ref).first
    head_commit = repo.commits(head_branch).first
    @common_ancestor = repo.commit(repo.git.merge_base({}, base_commit, head_commit))
  end

  def diff_stats(repo, a,b)
    stats = []
    Dir.chdir(path) do
      lines = repo.git.native(:diff, {:numstat => true, :M => true}, "#{a.id}...#{b.id}").split("\n")
      while !lines.empty?
        files = []
        while lines.first =~ /^([-\d]+)\s+([-\d]+)\s+(.+)/
          additions, deletions, filename = lines.shift.gsub(' => ', '=>').split
          additions, deletions = additions.to_i, deletions.to_i
          stat = Grit::DiffStat.new filename, additions, deletions
          stats << stat
        end
      end
      stats
    end
  end

  # FIXME maybe move to warpc/grit?
  def diff(repo, a, b)
    diff = repo.git.native('diff', {:M => true}, "#{a}...#{b}")

    if diff =~ /diff --git a/
      diff = diff.sub(/.*?(diff --git a)/m, '\1')
    else
      diff = ''
    end
    Grit::Diff.list_from_string(repo, diff)
  end

  def set_user_and_time user
    issue.closed_at = Time.now.utc
    issue.closer = user
  end

  def self.check_ref(record, attr, value)
    project = attr == :head_ref ? record.head_project : record.base_project
    if !((project.repo.branches_and_tags).map(&:name).include?(value) || project.repo.commits.map(&:id).include?(value))
      record.errors.add attr, I18n.t('projects.pull_requests.wrong_ref')
    end
  end

  protected

  def merge
    clone
    message = "Merge pull request ##{serial_id} from #{head_project.fullname}:#{head_ref}\r\n #{title}"
    %x(cd #{path} && git checkout #{base_ref} && git merge --no-ff #{head_branch} -m '#{message}')
  end

  def clone
    git = Grit::Git.new(path)

    unless git.exist?
      FileUtils.mkdir_p(path)
      system("git clone --local --no-hardlinks #{base_project.path} #{path}")
      if base_project != head_project
        Dir.chdir(path) do
          system 'git', 'remote', 'add', 'head', head_project.path
        end
      end
    end

    clean
    Dir.chdir(path) do
      system 'git', 'checkout', base_ref
      system 'git', 'pull',  'origin', base_ref
      if base_project == head_project
        system 'git', 'checkout', head_ref
        system 'git', 'pull', 'origin', head_ref
      else
        system 'git', 'fetch', 'head', "+#{head_ref}:#{head_branch}"
      end
    end
    # TODO catch errors
  end

  def clean
    Dir.chdir(path) do
      base_project.repo.branches.each {|branch| system 'git', 'checkout', branch.name}
      system 'git', 'checkout', base_ref

      base_project.repo.branches.each do |branch|
        system 'git', 'branch', '-D', branch.name unless [base_ref, head_branch].include? branch.name
      end
      base_project.repo.tags.each do |tag|
        system 'git', 'tag', '-d', tag.name unless [base_ref, head_branch].include? tag.name
      end
    end
  end

  def uniq_merge
    if base_project.pull_requests.needed_checking.where(:head_project_id => head_project, :base_ref => base_ref, :head_ref => head_ref).where('pull_requests.id <> :id or :id is null', :id => id).count > 0
      errors.add(:base_branch, I18n.t('projects.pull_requests.duplicate', :head_ref => head_ref))
    end
  end

  def clean_dir
    FileUtils.rm_rf path
  end
end
