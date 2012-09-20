# -*- encoding : utf-8 -*-
class Projects::Git::TreesController < Projects::Git::BaseController
  before_filter lambda{redirect_to @project if params[:treeish] == @project.default_branch and params[:path].blank?}, :only => :show
  before_filter :set_sha
  skip_before_filter :set_branch_and_tree, :only => :archive

  def show
    @tree = @tree / @path if @path.present?
    @commit = @branch.present? ? @branch.commit() : @project.repo.log(@treeish, @path, :max_count => 1).first
    render 'empty' unless @commit
  end

  def archive
    format = params[:format]
    if (@sha =~ /^#{@project.owner.uname}-#{@project.name}-/) && !(@sha =~ /[\s]+/) && (format =~ /^[\w]+$/)
      @sha = @sha.gsub(/^#{@project.owner.uname}-#{@project.name}-/, '')
      @commit = @project.repo.commits(@sha, 1).first
    end
    raise Grit::NoSuchPathError unless @commit
    name = "#{@project.owner.uname}-#{@project.name}-#{@sha}"
    fullname = "#{name}.#{format == 'tar' ? 'tar.gz' : 'zip'}"
    file = Tempfile.new fullname, 'tmp'
    system("cd #{@project.path}; git archive --format=#{format} --prefix=#{name}/ #{@sha} #{format == 'tar' ? ' | gzip -9' : ''} > #{file.path}")
    file.close
    send_file file.path, :disposition => 'attachment', :type => "application/#{format == 'tar' ? 'x-tar-gz' : 'zip'}", :filename => fullname
  end

  private

  def set_sha
    commit = @project.repo.commits(@treeish, 1).first
    @sha = commit ? commit.id : @treeish
  end

end
