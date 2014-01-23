class GitHook
  ZERO = '0000000000000000000000000000000000000000'
  @queue = :hook

  attr_reader :repo, :newrev, :oldrev, :newrev_type, :oldrev_type, :refname,
    :change_type, :rev, :rev_type, :refname_type, :owner, :project, :user, :message

  include Resque::Plugins::Status

  def self.perform(*options)
    self.process(*options)
  end

  def initialize(owner_uname, repo, newrev, oldrev, ref, newrev_type, user = nil, message = nil)
    @repo, @newrev, @oldrev, @refname, @newrev_type, @user, @message = repo, newrev, oldrev, ref, newrev_type, user, message
    if @owner = User.where(uname: owner_uname).first || Group.where(uname: owner_uname).first!
      @project = @owner.own_projects.where(name: repo).first!
    end
    @change_type, @user = git_change_type, find_user(user)
    git_revision_types
    commit_type
  end

  def git_change_type
    if oldrev == ZERO
      return 'create'
    elsif newrev == ZERO
      return 'delete'
    else
      return 'update'
    end
  end

  def git_revision_types
    case change_type
      when 'create', 'update'
        @rev = newrev
      when 'delete'
        @rev = oldrev
      end
      @rev_type = newrev_type
  end

  def commit_type
    if refname =~ /refs\/tags\/*/ && rev_type == 'commit'
        # un-annotated tag
        @refname_type= 'tag'
        #~ short_refname=refname + '##refs/tags/'
    elsif refname =~ /refs\/tags\/*/ && rev_type == 'tag'
        # annotated tag
        @refname_type="annotated tag"
        #~ short_refname= refname + '##refs/tags/'
    elsif refname =~ /refs\/heads\/*/ && rev_type == 'commit'
        # branch
        @refname_type= 'branch'
    elsif refname =~ /refs\/remotes\/*'/ && rev_type == 'commit'
      # tracking branch
      @refname_type="tracking branch"
      @short_refname= refname + '##refs/remotes/'
    else
        # Anything else (is there anything else?)
        @refname_type= "*** Unknown type of update to $refname (#{rev_type})"
    end
  end

  def self.process(*args)
    Modules::Observers::ActivityFeed::Git.create_notifications(args.size > 1 ? GitHook.new(*args) : args.first)
  end

  def find_user(user)
    if user.blank?
      # Local push
      User.find_by_email(project.repo.commit(newrev).author.email) rescue nil
    elsif user =~ /\Auser-\d+\Z/
      # git push over http
      User.find(user.gsub('user-', ''))
    elsif user =~ /\Akey-\d+\Z/
      # git push over ssh
      SshKey.find_by_id(user.gsub('key-', '')).try(:user)
    end
  end
end
