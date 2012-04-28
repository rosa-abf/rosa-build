class PullRequest < ActiveRecord::Base
  extend StateMachine::MacroMethods # no method state_machine WTF?!
  #TODO add validates to serialized data
  scope :needed_checking, where(:state => ['open', 'blocked', 'ready'])

  belongs_to :issue, :autosave => true, :dependent => :destroy, :touch => true, :validate => true
  belongs_to :base_project, :class_name => 'Project', :foreign_key => 'base_project_id'
  belongs_to :head_project, :class_name => 'Project', :foreign_key => 'head_project_id'
  delegate :user, :title, :body, :serial_id, :assignee, :to => :issue, :allow_nil => true
  accepts_nested_attributes_for :issue
  #attr_accessible #FIXME disable for development

  state_machine :initial => :open do
    #after_transition [:ready, :blocked] => [:merged, :closed] do |pull, transition|
    #  FileUtils.rm_rf(pull.path) # What about diff?
    #end

    event :ready do
      transition [:open, :blocked] => :ready
    end

    event :block do
      transition [:open, :ready] => :blocked
    end

    event :already do
      transition [:open, :blocked, :ready] => :already
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
    ret = merge
    if ret =~ /Already up-to-date/
      already
    elsif ret =~ /Merge made by recursive/
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

  def self.default_base_project(project)
    project.is_root? ? project : project.root
  end

  def clean #FIXME move to protected
    Dir.chdir(path) do
      base_project.branches.each {|branch| system 'git', 'checkout', branch.name}
      system 'git', 'checkout', base_ref

      base_project.branches.each do |branch|
        system 'git', 'branch', '-D', branch.name unless [base_ref, head_ref].include? branch.name
      end
      base_project.tags.each do |tag|
        system 'git', 'tag', '-d', tag.name unless [base_ref, head_ref].include? tag.name
      end
    end
  end

  protected

  def path
    filename = [id, base_project.owner.uname, base_project.name].join('-')
    if Rails.env == "production"
      File.join('/srv/rosa_build/shared/tmp', "pull_requests", filename)
    else
      File.join(Rails.root, "tmp", Rails.env, "pull_requests", filename)
    end
  end

  def merge
    clone
    %x(cd #{path} && git checkout #{base_ref} && git merge --no-ff #{head_ref}) #FIXME need sanitize branch name!
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
        system 'git', 'fetch', 'head', "+#{head_ref}:head_#{head_ref}"
      end
    end
    # TODO catch errors
  end
end
