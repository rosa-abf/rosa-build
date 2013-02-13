# -*- encoding : utf-8 -*-
class Projects::Git::TreesController < Projects::Git::BaseController
  before_filter lambda{redirect_to @project if params[:treeish] == @project.default_branch and params[:path].blank?}, :only => :show
  skip_before_filter :set_branch_and_tree, :set_treeish_and_path, :only => :archive

  def show
    @tree = @tree / @path if @path.present?
    @commit = @branch.present? ? @branch.commit() : @project.repo.log(@treeish, @path, :max_count => 1).first
    render 'empty' unless @commit
  end

  def archive
    format, @treeish = params[:format], params[:treeish]
    if (@treeish =~ /^#{@project.owner.uname}-#{@project.name}-/) && !(@treeish =~ /[\s]+/) && (format =~ /^(zip|tar\.gz)$/)
      @treeish = @treeish.gsub(/^#{@project.owner.uname}-#{@project.name}-/, '')
      @commit = @project.repo.commits(@treeish, 1).first
    end
    raise Grit::NoSuchPathError unless @commit
    name = "#{@project.owner.uname}-#{@project.name}-#{@treeish}"
    fullname = "#{name}.#{format == 'zip' ? 'zip' : 'tar.gz'}"
    file = Tempfile.new fullname, 'tmp'
    system("cd #{@project.path}; git archive --format=#{format == 'zip' ? 'zip' : 'tar'} --prefix=#{name}/ #{@treeish} #{format == 'zip' ? '' : ' | gzip -9'} > #{file.path}")
    file.close
    send_file file.path, :disposition => 'attachment', :type => "application/#{format == 'zip' ? 'zip' : 'x-tar-gz'}", :filename => fullname
  end

  def tags
    @tags = @project.repo.tags.sort_by(&:name)
  end

  def branches
    @branches = @project.repo.branches.sort_by(&:name).select{ |b| b.name != @branch.name }.unshift(@branch)
  end

end
