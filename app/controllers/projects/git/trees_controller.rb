class Projects::Git::TreesController < Projects::Git::BaseController
  before_filter lambda{redirect_to @project if params[:treeish] == @project.default_branch and params[:path].blank?}, :only => :show
  skip_before_filter :set_branch_and_tree, :set_treeish_and_path, :only => :archive

  def show
    render('empty') and return if @project.is_empty?
    @tree = @tree / @path if @path.present?
    @commit = @branch.present? ? @branch.commit() : @project.repo.log(@treeish, @path, :max_count => 1).first
    raise Grit::NoSuchPathError unless @commit
  end

  def archive
    format, @treeish = params[:format], params[:treeish]
    if (@treeish =~ /^#{@project.name}-/) && !(@treeish =~ /[\s]+/) && (format =~ /^(zip|tar\.gz)$/)
      @treeish = @treeish.gsub(/^#{@project.name}-/, '')
      @commit = @project.repo.commits(@treeish, 1).first
    end
    raise Grit::NoSuchPathError unless @commit
    tag   = @project.repo.tags.find{ |t| t.name == @treeish }
    sha1  = @project.get_project_tag_sha1(tag, format) if tag
    if sha1
      redirect_to "#{APP_CONFIG['file_store_url']}/api/v1/file_stores/#{sha1}"
    else
      archive = @project.archive_by_treeish_and_format @treeish, format
      send_file archive[:path], :disposition => 'attachment', :type => "application/#{format == 'zip' ? 'zip' : 'x-tar-gz'}", :filename => archive[:fullname]
    end
  end

  def tags
    @tags = @project.repo.tags.select{ |t| t.commit }.sort_by(&:name).reverse
    render 'refs'
  end

  def branches
    raise Grit::NoSuchPathError if params[:treeish] != @branch.try(:name) # get wrong branch name to nonempty project
    @branches = @project.repo.branches.sort_by(&:name).select{ |b| b.name != @branch.name }.unshift(@branch).compact if @branch
    render 'refs'
  end

end
