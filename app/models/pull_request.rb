class PullRequest < ActiveRecord::Base
  STATUSES = %w(ready already blocked merged closed)
  belongs_to :issue, :autosave => true, :dependent => :destroy, :touch => true, :validate => true
  belongs_to :to_project, :class_name => 'Project', :foreign_key => 'to_project_id'
  belongs_to :from_project, :class_name => 'Project', :foreign_key => 'from_project_id'
  delegate :user, :user_id, :title, :body, :serial_id, :assignee, :status, :to_param,
    :created_at, :updated_at, :comments, :status=, :to => :issue, :allow_nil => true

  validate :uniq_merge
  validates_each :from_ref, :to_ref do |record, attr, value|
    check_ref record, attr, value
  end

  before_create :clean_dir
  after_destroy :clean_dir

  accepts_nested_attributes_for :issue
  attr_accessible :issue_attributes, :to_ref, :from_ref

  scope :needed_checking, includes(:issue).where(:issues => {:status => ['open', 'blocked', 'ready']})

  state_machine :status, :initial => :open do
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

  def check(do_transaction = true)
    res = merge
    new_status = case res
                 when /Already up-to-date/
                   'already'
                 when /Merge made by/
                   system("cd #{path} && git reset --hard HEAD^") # remove merge commit
                   'ready'
                 when /Automatic merge failed/
                   system("cd #{path} && git reset --hard HEAD") # clean git index
                   'block'
                 else
                   raise res
                 end

    if do_transaction
      new_status == 'already' ? (ready; merging) : send(new_status)
      self.update_inline_comments
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

  def path
    filename = [id, from_project.owner.uname, from_project.name].compact.join('-')
    File.join(APP_CONFIG['root_path'], 'pull_requests', to_project.owner.uname, to_project.name, filename)
  end

  def head_branch
    if to_project != from_project
      "head_#{from_ref}"
    else
      from_ref
    end
  end

  def common_ancestor
    return @common_ancestor if @common_ancestor
    base_commit = repo.commits(to_ref).first
    head_commit = repo.commits(head_branch).first
    @common_ancestor = repo.commit(repo.git.merge_base({}, base_commit, head_commit)) || base_commit
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
    project = attr == :from_ref ? record.from_project : record.to_project
    record.errors.add attr, I18n.t('projects.pull_requests.wrong_ref') unless project.repo.branches_and_tags.map(&:name).include?(value)
  end

  def uniq_merge
    if to_project.pull_requests.needed_checking.where(:from_project_id => from_project, :to_ref => to_ref, :from_ref => from_ref).where('pull_requests.id <> :id or :id is null', :id => id).count > 0
      errors.add(:base_branch, I18n.t('projects.pull_requests.duplicate', :from_ref => from_ref))
    end
  end

  def repo
    return @repo if @repo.present? #&& !id_changed?
    @repo = Grit::Repo.new path
  end

  protected

  def merge
    clone
    message = "Merge pull request ##{serial_id} from #{from_project.name_with_owner}:#{from_ref}\r\n #{title}"
    %x(cd #{path} && git checkout #{to_ref} && git merge --no-ff #{head_branch} -m '#{message}')
  end

  def clone
    git = Grit::Git.new(path)
    unless git.exist?
      #~ FileUtils.mkdir_p(path)
      #~ system("git clone --local --no-hardlinks #{to_project.path} #{path}")
      options = {:bare => false, :shared => false, :branch => to_ref} # shared?
      git.fs_mkdir('..')
      git.clone(options, to_project.path, path)
      if to_project != from_project
        Dir.chdir(path) do
          system 'git', 'remote', 'add', 'head', from_project.path
        end
      end
      clean # Need testing
    end

    Dir.chdir(path) do
      system 'git', 'checkout', to_ref
      system 'git', 'pull',  'origin', to_ref
      if to_project == from_project
        system 'git', 'checkout', from_ref
        system 'git', 'pull', 'origin', from_ref
      else
        system 'git', 'fetch', 'head', "+#{from_ref}:#{head_branch}"
      end
    end
    # TODO catch errors
  end

  def clean
    Dir.chdir(path) do
      to_project.repo.branches.each {|branch| system 'git', 'checkout', branch.name}
      system 'git', 'checkout', to_ref

      to_project.repo.branches.each do |branch|
        system 'git', 'branch', '-D', branch.name unless [to_ref, head_branch].include? branch.name
      end
      to_project.repo.tags.each do |tag|
        system 'git', 'tag', '-d', tag.name unless [to_ref, head_branch].include? tag.name
      end
    end
  end

  def clean_dir
    FileUtils.rm_rf path
  end

  def update_inline_comments
    if self.comments.count > 0
      diff = self.diff self.repo, self.common_ancestor, repo.commits(self.head_branch).first
    end
    self.comments.each do |c|
      if c.data.present? # maybe need add new column 'actual'?
        c.actual_inline_comment? diff, true
        c.save
      end
    end
  end
end
