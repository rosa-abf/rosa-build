# -*- encoding : utf-8 -*-
class Projects::Git::TreesController < Projects::Git::BaseController
  before_filter lambda{redirect_to @project if params[:treeish] == @project.default_branch and params[:path].blank?}, :only => 'show'

  def show
    @tree = @tree / @path if @path.present?
    @commit = @branch.present? ? @branch.commit() : @project.repo.log(@treeish, @path, :max_count => 1).first
    render 'empty' unless @commit
  end

  def archive
    @commit = @project.repo.log(@treeish, nil, :max_count => 1).first
    raise Grit::NoSuchPathError unless @commit
    name = "#{@project.owner.uname}-#{@project.name}#{@project.repo.tags.include?(@treeish) ? "-#{@treeish}" : ''}-#{@commit.id[0..19]}"
    fullname = "#{name}.#{params[:format] == 'tar' ? 'tar.gz' : 'zip'}"
    file = Tempfile.new fullname, 'tmp'
    system("cd #{@project.path}; git archive --format=#{params[:format]} --prefix=#{name}/ #{@treeish} #{params[:format] == 'tar' ? ' | gzip -9' : ''} > #{file.path}")
    file.close
    send_file file.path, :disposition => 'attachment', :type => "application/#{params[:format] == 'tar' ? 'x-tar-gz' : 'zip'}", :filename => fullname
  end
end
