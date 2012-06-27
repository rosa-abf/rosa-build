# -*- encoding : utf-8 -*-
class GitHook
  attr_reader :repo, :newrev, :oldrev, :newrev_type, :oldrev_type, :refname,
                      :change_type, :rev, :rev_type, :refname_type, :owner, :project

  include Resque::Plugins::Status

  def initialize(owner_uname, repo, newrev, oldrev, ref, newrev_type, oldrev_type = nil)
    @repo, @newrev, @oldrev, @refname, @newrev_type, @oldrev_type = repo, newrev, oldrev, ref, newrev_type, oldrev_type
    if @owner = User.where(:uname => owner_uname).first || Group.where(:uname => owner_uname).first!
      @project = @owner.own_projects.where(:name => repo).first!
    end
    @change_type = git_change_type
    git_revision_types
    commit_type
  end

  def git_change_type
    if @oldrev =~ /0+$/
      return 'create'
    elsif @newrev =~ /0+$/
      return 'delete'
    else
      return 'update'
    end
  end

  def git_revision_types
    case @change_type
      when 'create', 'update'
        @rev = @newrev
        @rev_type = @newrev_type
      when 'delete'
        @rev = @oldrev
        @rev_type = @oldrev_type
    end
  end

  def commit_type
    if @refname =~ /refs\/tags\/*/ && @rev_type == 'commit'
        # un-annotated tag
        @refname_type= 'tag'
        #~ short_refname=refname + '##refs/tags/'
    elsif @refname =~ /refs\/tags\/*/ && @rev_type == 'tag'
        # annotated tag
        @refname_type="annotated tag"
        #~ short_refname= refname + '##refs/tags/'
    elsif @refname =~ /refs\/heads\/*/ && @rev_type == 'commit'
        # branch
        @refname_type= 'branch'
    elsif @refname =~ /refs\/remotes\/*'/ && @rev_type == 'commit'
      # tracking branch
      @refname_type="tracking branch"
      @short_refname= @refname + '##refs/remotes/'
    else
        # Anything else (is there anything else?)
        @refname_type= "*** Unknown type of update to $refname (#{rev_type})"
    end
  end

  def self.process(*args)
    ActivityFeedObserver.instance.after_create(args.size > 1 ? GitHook.new(*args) : args.first)
  end
end
