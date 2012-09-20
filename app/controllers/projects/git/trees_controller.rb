# -*- encoding : utf-8 -*-
class Projects::Git::TreesController < Projects::Git::BaseController
  before_filter lambda{redirect_to @project if params[:treeish] == @project.default_branch and params[:path].blank?}, :only => :show
  skip_before_filter :set_branch_and_tree, :only => :archive

  def show
    @tree = @tree / @path if @path.present?
    @commit = @branch.present? ? @branch.commit() : @project.repo.log(@treeish, @path, :max_count => 1).first
    render 'empty' unless @commit
  end

  def archive
    format = params[:format]
    if (@treeish =~ /^#{@project.owner.uname}-#{@project.name}-/) && !(@treeish =~ /[\s]+/) && (format =~ /^[\w]+$/)
      @treeish = @treeish.gsub(/^#{@project.owner.uname}-#{@project.name}-/, '')
      @commit = @project.repo.commits(@treeish, 1).first
    end
    raise Grit::NoSuchPathError unless @commit
    name = "#{@project.owner.uname}-#{@project.name}-#{@treeish}"
    fullname = "#{name}.#{format == 'tar' ? 'tar.gz' : 'zip'}"
    file = Tempfile.new fullname, 'tmp'
    system("cd #{@project.path}; git archive --format=#{format} --prefix=#{name}/ #{@treeish} #{format == 'tar' ? ' | gzip -9' : ''} > #{file.path}")
    file.close
    send_file file.path, :disposition => 'attachment', :type => "application/#{format == 'tar' ? 'x-tar-gz' : 'zip'}", :filename => fullname
  end

end
